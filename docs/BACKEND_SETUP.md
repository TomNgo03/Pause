# Social and AI Backend Setup

The iOS app includes a fully interactive local Demo Mode. Production accounts, cross-device social state, and AI calls use a Supabase project and Edge Function.

## Setup

1. Create a Supabase project intended only for this pilot.
2. Apply `supabase/migrations/001_pause_social.sql` after reviewing every policy.
3. Deploy `supabase/functions/ai-plan` and `supabase/functions/delete-account`.
4. Set Edge Function secrets: `OPENAI_API_KEY` and `OPENAI_MODEL`. Supabase supplies its URL and keys.
5. Set `PAUSE_AI_ENDPOINT` in the app Info configuration to the deployed function URL.
6. Add an authenticated bearer token to `AIPlanningService` before enabling remote mode. The current client deliberately falls back offline until authentication is wired.
7. Test with separate accounts that one user cannot read another user's profile, circle, room, reaction, or AI quota.

Account deletion is server-side because only a trusted function may use the service-role credential. Deleting the auth user cascades through the social tables.

## Security release gate

Do not invite pilot users until automated authorization tests demonstrate cross-user isolation. Never add the OpenAI or Supabase service-role key to the iOS application, repository, plist, or build settings.

## AI design

The server moderates input, limits task length, enforces daily quota, requests strict structured JSON, disables response-object storage with `store: false`, validates durations again, and returns only the draft plan. The user must approve it locally.
