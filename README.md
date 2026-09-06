# Pause

Pause is a privacy-first iOS app that helps students turn automatic app opening into intentional digital use.

The product asks three small questions:

1. What do you want to accomplish?
2. How much time do you need?
3. Did you accomplish your intention?

The repository contains a one-month, university-portfolio-ready MVP built with SwiftUI and SwiftData. It runs in **Prototype Mode** without special permissions and contains an entitlement-ready boundary for Apple's Family Controls, Managed Settings, and Device Activity frameworks.

## Current scope

- Ethical onboarding and privacy disclosure
- Intention and duration planning
- Recoverable session timer
- Optional end-of-session reflection
- Private seven-day dashboard
- Local-only SwiftData persistence
- Anonymous CSV export
- Complete local-data deletion
- Screen Time service abstraction with prototype fallback
- Unit tests for session and analytics logic
- Private pseudonymous profiles and friend codes
- Accountability circles and cooperative challenges
- Interactive focus rooms and preset encouragement reactions
- Guided AI planning coach with a deterministic offline fallback
- Supabase schema, row-level security, authentication client, and OpenAI Edge Function

## Requirements

- macOS with Xcode 16 or newer
- iOS 17 or newer target
- A physical iPhone for Screen Time testing
- Apple Developer Program membership and Family Controls entitlement for external distribution
- XcodeGen (`brew install xcodegen`) to generate the Xcode project

## Run

```bash
xcodegen generate
open Pause.xcodeproj
```

Select the `Pause` scheme and an iOS simulator. Prototype Mode requires no Screen Time entitlement.

The generated project intentionally has no restricted entitlement attached, so Prototype Mode can run immediately. For device-level shielding, configure the App Group and Family Controls capability in the Apple Developer portal, attach `Pause/Resources/Pause.entitlements`, enable the `PAUSE_SCREEN_TIME` compilation condition, and follow [docs/SCREEN_TIME_SETUP.md](docs/SCREEN_TIME_SETUP.md).

## Project documents

- [Product and implementation plan](docs/IMPLEMENTATION_PLAN.md)
- [Ethics and privacy](docs/ETHICS_AND_PRIVACY.md)
- [Pilot protocol](docs/PILOT_PROTOCOL.md)
- [Screen Time setup](docs/SCREEN_TIME_SETUP.md)
- [Social and AI backend setup](docs/BACKEND_SETUP.md)
- [AI use disclosure template](AI_USAGE.md)

## Important limitation

Pause is a digital-wellbeing reflection tool, not a medical device. It does not diagnose or treat addiction, ADHD, anxiety, depression, or any other health condition.
