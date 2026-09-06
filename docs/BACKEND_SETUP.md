# Pause Backend and Authentication Setup

Pause uses Supabase project `zbfvjtxfvdlnjleozlid`. The app has no guest or demo mode: a valid account session is required before any feature appears.

## Already implemented

- Email/password login
- Verified signup using a six-digit email code
- Forgot-password recovery using a six-digit email code
- Secure access and rotating refresh-token storage in the iOS Keychain
- Session restoration at launch and server-side logout
- Google and Apple OAuth entry points through the system authentication browser
- Custom callback URL: `pause://auth-callback`
- Server-side account deletion

## Required Supabase dashboard configuration

These settings use credentials owned by the student and cannot safely be committed to Git.

### 1. URL Configuration

Open **Authentication → URL Configuration** and add this Redirect URL exactly:

```text
pause://auth-callback
```

### 2. Six-digit signup email

Open **Authentication → Emails → Templates → Confirm signup**.

- Subject: `Your Pause verification code`
- Replace the body with [`supabase/templates/confirmation.html`](../supabase/templates/confirmation.html).
- Confirm that the body contains `{{ .Token }}`, not only `{{ .ConfirmationURL }}`.

### 3. Six-digit password-reset email

Open **Authentication → Emails → Templates → Reset password**.

- Subject: `Reset your Pause password`
- Replace the body with [`supabase/templates/recovery.html`](../supabase/templates/recovery.html).
- Confirm that the body contains `{{ .Token }}`.

For a classroom pilot, Supabase's default mail sender is sufficient but rate-limited. Configure a custom SMTP provider before a public launch.

### 4. Google login

1. In Google Auth Platform, configure the `openid`, email, and profile scopes.
2. Create a **Web application** OAuth client.
3. Add Supabase's callback URL: `https://zbfvjtxfvdlnjleozlid.supabase.co/auth/v1/callback`.
4. In **Supabase → Authentication → Sign In / Providers → Google**, enable Google and paste the client ID and client secret.
5. Keep the Google secret only in Supabase—never in Xcode, `Info.plist`, or Git.

### 5. Apple login

1. An Apple Developer Program membership is required.
2. Create an App ID for bundle ID `org.pauseproject.app` and enable Sign in with Apple.
3. Create a Services ID and associate it with that App ID.
4. Configure domain `zbfvjtxfvdlnjleozlid.supabase.co` and return URL `https://zbfvjtxfvdlnjleozlid.supabase.co/auth/v1/callback`.
5. Create an Apple signing key, then configure the Services ID and generated secret in **Supabase → Authentication → Sign In / Providers → Apple**.
6. Record a reminder to rotate the Apple OAuth secret before its six-month expiry.

## Social and AI backend

1. Migration `001_pause_social.sql` is applied to the linked project.
2. Edge Functions `ai-plan` and `delete-account` are deployed.
3. Set `OPENAI_API_KEY` and optionally `OPENAI_MODEL` as Edge Function secrets.
4. Before inviting pilot users, verify with two separate accounts that row-level security prevents either account from reading the other's private data.

## Manual acceptance test

1. Delete Pause from the simulator to clear old prototype preferences, then reinstall.
2. Confirm the welcome screen appears and no app feature can be opened without authentication.
3. Create an account and enter the emailed six-digit code.
4. Complete onboarding, log out, and log back in with the password.
5. Force-quit and relaunch; verify the session is restored.
6. Request a password reset, enter its code, set a new password, and log in with it.
7. Test Google and Apple individually after their provider dashboards are configured.

## Security release gate

Never add the OpenAI key, Supabase service-role key, Google client secret, Apple `.p8` key, or Apple client secret to this repository or the iOS app. Pause is a wellbeing tool—not a medical product—and must not claim to diagnose or treat addiction or mental-health conditions.
