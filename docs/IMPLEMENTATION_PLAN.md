# Pause: One-Month Product and Technical Plan

## Outcome

At the end of four weeks, Pause should be a stable native iOS MVP, a private beta candidate, and a self-contained university portfolio project. A reviewer must be able to understand it without installing it.

## Product hypothesis

A short, voluntary intention-setting step before a distracting session may help students notice automatic use and feel more agency over their decisions.

Pause does not assume that all screen time is harmful or that reducing minutes is always beneficial.

## MVP user story

As a student, I can choose an intention and duration before a digital session, see when my plan ends, optionally reflect afterward, and privately review my patterns.

## Definition of done

- A first-time user can complete onboarding without assistance.
- A session can be planned in under 20 seconds.
- Active-session state survives app termination.
- Expired sessions are reconciled on relaunch.
- Every reflection question can be skipped.
- No account, advertising SDK, location, contacts, messages, or browsing content is collected.
- A user can export anonymous records and delete all local data.
- Core rules have unit tests.
- Screen Time failure never prevents Prototype Mode from working.

## Architecture

The app uses four layers:

1. **Views:** SwiftUI screens with no direct platform API manipulation.
2. **App model:** Navigation, current session, and user actions.
3. **Domain:** Session rules and aggregate calculations.
4. **Services:** Persistence, notifications, export, and Screen Time shielding.

SwiftData is the local source of truth for completed records. `UserDefaults` stores lightweight preferences and crash-recovery state. Screen Time functionality is accessed through `ScreenTimeControlling`, allowing a prototype implementation during simulator development.

## Four-week execution

### Week 1 — foundations

- Validate app shielding on a physical device.
- Conduct three short problem interviews.
- Freeze MVP requirements.
- Implement onboarding, navigation, design system, models, and session state machine.
- Create the portfolio website outline and capture development evidence.

### Week 2 — complete product loop

- Implement intention and duration planning.
- Implement active timer using an absolute expiration date.
- Implement finish, cancel, and five-minute extension.
- Implement optional reflection and SwiftData storage.
- Implement notification scheduling and app-lifecycle recovery.

### Week 3 — quality and privacy

- Implement dashboard and neutral insights.
- Implement CSV export and deletion.
- Add unit/UI testing and accessibility review.
- Test permission denial, termination, restart, large text, dark mode, and empty data.
- Run a three-person usability test and fix repeated problems.

### Week 4 — pilot and evidence

- Freeze the pilot build.
- Run a voluntary 5–7 day pilot with 8–12 students, subject to school and guardian requirements.
- Analyze descriptive results only.
- Produce a two-minute demo, 5–7 page report, screenshots, architecture diagram, cleaned Git history, and portfolio website.

## Priority order

1. Reliable session state
2. Privacy and deletion
3. Complete user journey
4. Screen Time integration
5. Tests and accessibility
6. Dashboard polish
7. Portfolio assets

The approved expanded build adds private accounts, circles, focus rooms, cooperative challenges, preset encouragement, and a bounded AI planning coach. It still excludes public discovery, open chat, leaderboards, parent surveillance, grades, and Android support.

## Key risks

| Risk | Response |
|---|---|
| Family Controls entitlement delay | Ship and demonstrate Prototype Mode; document the integration boundary |
| iOS cannot show a full form over another app | Shield directs the user to Pause; Pause starts the intentional session |
| Background expiration is unreliable | Store absolute end time; use Device Activity when enabled; reconcile on every launch |
| Prompts become irritating | Keep interaction under 20 seconds, allow override/skip, collect annoyance feedback |
| Pilot is too small for causal claims | Report counts, percentages, limitations, and interview themes only |
| AI-generated code is not understood | Require tests, code review, explanation, and `AI_USAGE.md` updates per feature |

## University evidence package

- Public portfolio webpage
- 90–120 second working demonstration
- Version-controlled codebase
- Architecture and privacy explanation
- Anonymized pilot summary
- Honest account of failures, changes, mentorship, and AI use
- Optional private TestFlight access
