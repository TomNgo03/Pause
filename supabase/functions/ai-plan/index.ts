const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type" };
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const supabaseURL = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const openAIKey = Deno.env.get("OPENAI_API_KEY")!;
  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-5.4-mini";
  const authorization = req.headers.get("Authorization") ?? "";

  const userResponse = await fetch(`${supabaseURL}/auth/v1/user`, { headers: { Authorization: authorization, apikey: anonKey } });
  if (!userResponse.ok) return json({ error: "unauthorized" }, 401);
  const user = await userResponse.json();

  const quotaResponse = await fetch(`${supabaseURL}/rest/v1/rpc/consume_ai_quota`, {
    method: "POST", headers: { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey, "Content-Type": "application/json" },
    body: JSON.stringify({ target_user: user.id, daily_limit: 10 })
  });
  if (!quotaResponse.ok || await quotaResponse.json() !== true) return json({ error: "daily_limit_reached" }, 429);

  const input = await req.json();
  const task = String(input.task ?? "").trim().slice(0, 500);
  const available = Math.max(10, Math.min(180, Number(input.availableMinutes ?? input.available_minutes ?? 30)));
  if (!task) return json({ error: "task_required" }, 400);

  const moderation = await fetch("https://api.openai.com/v1/moderations", {
    method: "POST", headers: { Authorization: `Bearer ${openAIKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: "omni-moderation-latest", input: task })
  });
  const moderationBody = await moderation.json();
  if (!moderation.ok || moderationBody.results?.[0]?.flagged) {
    return json({ error: "This planning request needs support beyond a productivity coach. Please talk with a trusted adult or qualified professional." }, 422);
  }

  const schema = {
    type: "object", additionalProperties: false,
    required: ["title", "summary", "total_minutes", "steps", "safety_note"],
    properties: {
      title: { type: "string", maxLength: 80 }, summary: { type: "string", maxLength: 240 },
      total_minutes: { type: "integer", minimum: 1, maximum: 180 }, safety_note: { type: ["string", "null"], maxLength: 160 },
      steps: { type: "array", minItems: 1, maxItems: 5, items: { type: "object", additionalProperties: false,
        required: ["title", "duration_minutes", "break_minutes", "intention"], properties: {
          title: { type: "string", maxLength: 100 }, duration_minutes: { type: "integer", minimum: 1, maximum: 60 },
          break_minutes: { type: "integer", minimum: 0, maximum: 20 },
          intention: { type: "string", enum: ["Reply to a message", "Find specific information", "Learn something", "View planned content", "Connect with someone", "Take a short break", "Other"] }
        }
      } }
    }
  };

  const aiResponse = await fetch("https://api.openai.com/v1/responses", {
    method: "POST", headers: { Authorization: `Bearer ${openAIKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model, store: false, max_output_tokens: 800, safety_identifier: `pause_${user.id}`,
      instructions: "You are Pause Planning Coach for teenage students. Create a realistic editable productivity plan, not medical or mental-health advice. Protect sleep, meals, movement, safety, and urgent communication. Never shame, diagnose, or promise grades. Stay within the user's available time.",
      input: JSON.stringify({ ...input, task, available_minutes: available }),
      text: { format: { type: "json_schema", name: "pause_plan", strict: true, schema } }
    })
  });
  const body = await aiResponse.json();
  if (!aiResponse.ok || !body.output_text) return json({ error: "generation_failed" }, 502);
  try {
    const plan = JSON.parse(body.output_text);
    const computed = plan.steps.reduce((sum: number, step: {duration_minutes:number; break_minutes:number}) => sum + step.duration_minutes + step.break_minutes, 0);
    if (computed > Math.min(180, available + 10)) return json({ error: "invalid_plan" }, 502);
    plan.total_minutes = computed;
    return json(plan);
  } catch { return json({ error: "invalid_plan" }, 502); }
});
