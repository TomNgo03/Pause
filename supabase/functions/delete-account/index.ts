const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type" };
const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "DELETE") return reply({ error: "method_not_allowed" }, 405);
  const base = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authorization = req.headers.get("Authorization") ?? "";
  const userResponse = await fetch(`${base}/auth/v1/user`, { headers: { Authorization: authorization, apikey: anon } });
  if (!userResponse.ok) return reply({ error: "unauthorized" }, 401);
  const user = await userResponse.json();
  const deletion = await fetch(`${base}/auth/v1/admin/users/${user.id}`, {
    method: "DELETE", headers: { Authorization: `Bearer ${service}`, apikey: service }
  });
  return deletion.ok ? reply({ deleted: true }) : reply({ error: "deletion_failed" }, 502);
});

