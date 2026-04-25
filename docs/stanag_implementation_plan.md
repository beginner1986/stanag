# STANAG 6001 English Learning App — Implementation Plan

**Version:** 1.0  
**Date:** April 2026  
**Estimated duration:** ~20 weeks  
**Team:** 1 developer (Flutter/Firebase) + 1 methodology partner (content)  

---

## Overview

| Phase | Name | Weeks | Owner |
|---|---|---|---|
| 0 | Project foundation | 1–2 | Developer |
| 1 | Authentication and user shell | 3–5 | Developer |
| 2 | Content engine and lesson player | 6–11 | Developer + Methodology partner |
| 3 | Daily loop, progress and motivation | 12–16 | Developer |
| 4 | Polish, testing and launch | 17–20 | Developer + Methodology partner |

**Parallelism note:** The methodology partner is not blocked during Phases 0 and 1. Content drafting in Google Docs begins immediately and continues throughout. Structured content entry into the admin panel begins when Phase 2 delivers the admin panel (approx. week 8).

---

## Phase 0 — Project foundation
**Weeks 1–2 | Owner: Developer**

### Environment setup

- [x] Create Firebase project on Blaze plan, region `europe-central2`
  - Set $5/month budget alert immediately after creation
- [x] Enable Firebase services: Auth, Firestore, Storage, FCM, Analytics, Crashlytics
- [x] Set Firestore Security Rules — content public read, user data private
- [x] Initialise Flutter project with three flavours: `dev`, `staging`, `prod`
  - Each flavour connects to its own Firebase project
- [x] Set up version control (Git) with branch strategy: `main`, `develop`, `feature/*`
- [x] Configure CI pipeline (GitHub Actions) — lint, test, and build on every PR

### Core packages

Dependencies are added as needed at the start of each phase, not upfront. This keeps `pubspec.yaml` honest, surfaces version conflicts in context, and makes it easier to attribute any dependency issue to the feature that introduced it.

| Phase | Packages to add |
|---|---|
| Phase 0 | `flutter_localizations`, `intl`, `shared_preferences` |
| Phase 1 | `firebase_auth`, `cloud_firestore`, `flutter_riverpod`, `go_router`, `purchases_flutter` |
| Phase 2 | `firebase_storage`, `just_audio` |
| Phase 3 | `firebase_messaging`, `flutter_local_notifications`, `google_mobile_ads`, `firebase_analytics`, `firebase_crashlytics` |

`firebase_core` is already present from `flutterfire configure`. Add each package with `flutter pub add <package>` to let pub resolve the correct version automatically — do not hand-pin versions in `pubspec.yaml`.

### Localisation scaffold

- [x] Create `l10n.yaml` and `.arb` files for Polish (`app_pl.arb`) and English (`app_en.arb`)
  - All UI strings go into `.arb` files from day one — no hardcoded strings anywhere
- [x] Implement language switcher; persist choice to `SharedPreferences`
- [x] Confirm `.arb` generation is wired into the build process

### Definition of done

A blank Flutter app builds and runs on Android and web for all three flavours. Phase 0 packages (`flutter_localizations`, `intl`, `shared_preferences`) resolve without conflicts. Language switcher toggles between PL and EN on a test screen. CI pipeline passes on a sample PR.

---

## Phase 1 — Authentication and user shell
**Weeks 3–5 | Owner: Developer**

### Anonymous auth

- [x] Implement silent anonymous sign-in on first app launch
- [x] Create minimal `USERS` document in Firestore on first launch (`is_anonymous: true`)
- [x] Build auth state provider (Riverpod) — app reacts to all four user states:
  - `anonymous`, `registered_free`, `registered_premium`, `expired_premium`

### Registration and sign-in

- [x] Build sign-up screen — email + password, link to anonymous UID via `linkWithCredential()`
- [x] Handle email-already-exists edge case — offer login and manually merge day 1 progress
- [x] Build login screen
- [x] Build password reset flow (Firebase email, Polish copy and app branding)
- [ ] Customise Firebase Auth email templates in console

### Navigation shell

- [ ] Implement GoRouter with auth-gated routes
  - Unauthenticated → onboarding/lesson (anonymous allowed)
  - Registered → full app
- [x] Build bottom navigation bar: Home, Progress, Settings
- [ ] Build Settings screen:
  - Language toggle (PL/EN)
  - Notification toggle and time picker
  - Sign-out
  - Account info (email, account type)
  - Link to privacy policy and terms of service

### Premium entitlement

- [ ] Integrate RevenueCat Flutter SDK (`purchases_flutter`)
- [ ] Configure subscription products in Google Play Console
- [ ] Write Cloud Function webhook: RevenueCat event → set JWT custom claim → update `USERS` document
  - `is_premium` must only ever be set server-side via this webhook
  - Set function region explicitly to `europe-central2` — the default is `us-central1` and will not be caught by the compiler
- [ ] Build upgrade screen: feature list, pricing, Google Play Billing sheet
- [ ] Force JWT token refresh on client immediately after purchase confirmation

### Definition of done

Full auth loop works end-to-end: anonymous launch → day 1 → sign-up (anonymous UID preserved) → login → password reset → premium upgrade → premium features gated correctly. All routes auth-gated. Settings screen functional.

---

## Phase 2 — Content engine and lesson player
**Weeks 6–11 | Owner: Developer + Methodology partner**

### Content schema

- [ ] Agree controlled vocabularies with methodology partner before any content entry:
  - `skill_focus` values: `vocabulary`, `grammar`, `listening`, `reading`, `mixed`
  - `difficulty` scale: 1–5 with written definition per level
  - `type` values for exercises: `vocabulary_flashcard`, `multiple_choice`, `gap_fill`, `listening_comprehension`, `true_false`
- [ ] Seed Firestore with schema — at least one level, one unit, one lesson, one of each exercise type
- [ ] Document JSON `options` structure for each exercise type (reference: app specification appendix A)

### Admin panel

The admin panel is a Flutter web app, password-protected behind a Firebase Auth admin role. All writes go through Cloud Functions using the Admin SDK — the content editor never has direct Firestore write access.

- [ ] Set up separate admin Firebase Auth role; assign to methodology partner account
- [ ] Build admin panel scaffold — auth-gated Flutter web app, deployed to separate Hosting URL
- [ ] Build level and unit management (create, edit, reorder, publish/unpublish)
- [ ] Build lesson editor (create, edit, reorder within unit, publish/unpublish)
- [ ] Build exercise editor — all five exercise types with type-appropriate form fields
- [ ] Build audio upload interface — file picker, upload to Firebase Storage, TTS/recorded toggle, URL stored in exercise document
- [ ] Build publish/unpublish toggle with preview mode (view content as a user would)
- [ ] Build daily motivational quote editor (day number, PL text, EN text, author)

### Exercise widgets (app)

- [ ] `vocabulary_flashcard` — word, translation, audio button, example sentence, flip animation
- [ ] `multiple_choice` — question, 4 tap-to-select options, animated correct/incorrect feedback
- [ ] `gap_fill` — sentence with blank, tap-to-insert word tokens from bank
- [ ] `listening_comprehension` — audio player with play/pause/replay, question, options
- [ ] `true_false` — statement, two-button interface, feedback animation

All widgets must:
  - Show correct/incorrect animated feedback after answering
  - Display explanation (PL or EN based on interface language) after answer
  - Write to `USER_EXERCISE_LOG` immediately on answer

### Lesson player and session flow

- [ ] Build lesson player — horizontal progress bar, exercise card carousel, transition animations
- [ ] Build session result screen:
  - Score (percentage)
  - XP earned
  - Streak day badge
  - Day 2 preview (title and exercise count)
  - Sign-up prompt card for anonymous users
- [ ] Implement batch write at session end — write to `USER_PROGRESS`, `USER_STREAKS`, `DAILY_PLANS` in one batch operation (not per-exercise, to minimise Firestore write costs)

### Audio and offline

- [ ] Implement audio pre-caching — on app open over Wi-Fi, fetch and cache today's audio files locally
- [ ] Enable Firestore offline persistence for lesson and exercise content
- [ ] Verify offline lesson playback works after airplane mode enabled

### Definition of done

Methodology partner can log into admin panel and create a complete lesson (unit → lesson → 5 exercises of different types, with audio). A user can open the app, complete that lesson, and see a result screen. Progress is written to Firestore. Anonymous user sees sign-up prompt. Audio plays offline after initial cache.

---

## Phase 3 — Daily loop, progress and motivation
**Weeks 12–16 | Owner: Developer**

### Daily plan system

- [ ] Build Cloud Function: daily plan generator
  - Runs at midnight (Europe/Warsaw timezone)
  - Assigns lessons to each active user for the next day
  - Set function region explicitly to `europe-central2`
  - Writes `DAILY_PLANS` document per user
- [ ] Build home screen:
  - Today's plan card (lesson count, estimated time)
  - Streak counter with flame indicator
  - Daily motivational quote (PL or EN based on interface language)
  - "Start today's lesson" CTA
- [ ] Implement free tier daily exercise cap: 10 exercises/day with upgrade prompt when limit hit

### Spaced repetition

- [ ] Implement Leitner box SR algorithm using `USER_EXERCISE_LOG.next_review_at`
  - Correct answer: move to next box (longer interval)
  - Incorrect answer: return to box 1 (short interval)
  - Calculate and write `next_review_at` on every exercise answer
- [ ] Build review mode — surfaces due exercises from completed lessons, accessible from home screen

### Streaks and motivation

- [ ] Implement streak logic:
  - Increment `current_streak` on each daily plan completion
  - Allow one missed day before streak breaks (flexible catch-up window)
  - Update `longest_streak` when current exceeds it
  - Write to `USER_STREAKS` at end of each session
- [ ] Build streak milestone celebrations: animated screen on day 7, 30, 60, 100
- [ ] Implement daily FCM push notification:
  - Default time: 19:00 local
  - User-configurable send time in Settings
  - Localised copy (PL/EN)
  - Respect system notification permissions

### Progress screen

- [ ] Build progress screen:
  - Overall STANAG Level 1 completion bar
  - Unit-by-unit breakdown with completion status
  - Current streak and longest streak
  - Total XP earned
- [ ] Build per-skill analytics (premium only):
  - Vocabulary / grammar / listening score trends over time
  - Weak area identification (lowest scoring skill)
  - Targeted review suggestions based on weak areas
- [ ] Build course completion screen — three-branch flow:
  1. Schedule real exam (link to STANAG exam information)
  2. Enter infinite spaced repetition review mode
  3. Level 2 upsell (premium gate; Level 2 content in v2)

### Ads

- [ ] Integrate AdMob SDK
- [ ] Configure interstitial ad — shown to free users between sessions (not mid-lesson)
- [ ] Configure banner ad — shown to free users on home screen
- [ ] Configure AdMob content filters — exclude: gambling, alcohol, weapons, political, adult
- [ ] Verify ads do not appear for premium users

### Definition of done

A registered free user opens the app each day, sees today's plan, completes lessons, earns XP, sees streak update, and receives a push notification reminder. After 10 exercises, upgrade prompt appears. Streak milestone animation fires on day 7. Progress screen shows correct data. Premium user sees per-skill analytics and no ads.

---

## Phase 4 — Polish, testing and launch
**Weeks 17–20 | Owner: Developer + Methodology partner**

### Content readiness (Methodology partner)

- [ ] Minimum 4 complete weeks of content entered and published in admin panel
  - All five exercise types represented in each week
  - Audio files uploaded for all listening exercises
- [ ] Audio quality review — consistency check between TTS and recorded audio
- [ ] Motivational quotes written and entered for days 1–30 (PL + EN)
- [ ] All exercise explanations reviewed for accuracy and tone

### Testing — unit and widget

- [ ] Unit tests: Leitner box SR algorithm (correct/incorrect interval calculation)
- [ ] Unit tests: streak logic (increment, miss, break, longest streak update)
- [ ] Unit tests: daily plan generator (lesson assignment, edge cases)
- [ ] Unit tests: batch write logic (correct documents written, correct values)
- [ ] Widget tests: all five exercise widgets (render, interaction, feedback animation)
- [ ] Widget tests: lesson player (progress bar, navigation, completion trigger)
- [ ] Widget tests: session result screen (score display, sign-up prompt visibility)

### Testing — integration and end-to-end

- [ ] Full user journey test: anonymous launch → day 1 → sign-up → day 2 → upgrade to premium → complete lesson as premium user
- [ ] Edge case: email-already-exists during sign-up
- [ ] Edge case: subscription expiry → premium features correctly revoked
- [ ] Edge case: streak broken after two missed days
- [ ] Offline test: enable airplane mode mid-lesson, complete lesson, re-enable connectivity, verify sync

### Device and browser testing

- [ ] Test on minimum 3 real Android devices:
  - Low-spec (Android 9, 2 GB RAM)
  - Mid-spec (Android 11, 4 GB RAM)
  - High-spec (Android 13, 8 GB RAM)
- [ ] Test web version on: Chrome (desktop), Chrome (Android), Firefox (desktop), Safari (iOS)
- [ ] Verify audio playback on all devices and browsers
- [ ] Verify AdMob ads display correctly on Android (not on web)

### Legal and compliance

- [ ] Write RODO-compliant privacy policy in Polish and English
  - Cover: data collected, storage location (EU), retention period, user rights, contact
- [ ] Write terms of service in Polish and English
  - Cover: subscription terms, refund policy, content IP, acceptable use
- [ ] Add privacy policy and terms links to: Settings screen, sign-up screen, Play Store listing
- [ ] Add cookie/tracking consent banner for web version (GDPR requirement)
- [ ] Verify Firebase App Check is enabled on production project

### Google Play Store

- [ ] Create Google Play developer account (one-time $25 fee)
- [ ] Prepare store assets:
  - App icon (512×512 PNG)
  - Feature graphic (1024×500 PNG)
  - Minimum 4 screenshots in Polish (phone format)
  - Short description (80 chars, PL)
  - Full description (4000 chars, PL)
- [ ] Configure content rating questionnaire
- [ ] Set up subscription products in Play Console (linked to RevenueCat)
- [ ] Internal test track (developer accounts only) — smoke test
- [ ] Closed beta (10–20 real soldiers) — collect feedback, fix critical issues
- [ ] Open beta — broader exposure, monitor Crashlytics and Analytics
- [ ] Production release

### Web deployment

- [ ] Deploy Flutter web build to Firebase Hosting (`prod` project)
- [ ] Configure custom domain and SSL certificate
- [ ] Verify web build on Hosting matches tested build

### Operations

- [ ] Set up email support inbox (referenced in app as support contact)
- [ ] Verify Firebase Analytics events firing correctly for all key actions
- [ ] Verify Crashlytics is receiving reports from production build
- [ ] Document monthly update process for methodology partner (content entry workflow)
- [ ] Set Firebase budget alert on production project ($5/month initial threshold)

### Definition of done

App is live on Google Play Store (production) and Firebase Hosting. All critical user journeys work on real devices. Crashlytics active. Analytics events verified. Privacy policy and terms published. Support inbox active. Methodology partner has documented workflow for monthly content updates.

---

## Dependency map

The following dependencies determine scheduling risk. If any of these slip, downstream phases are affected.

```
Controlled vocabulary agreement (Phase 2 start)
  → Admin panel build (Phase 2, weeks 6–8)
    → Methodology partner content entry (Phase 2, weeks 8–11)
      → Content readiness for testing (Phase 4, week 17)

Daily plan generator (Phase 3)
  → Home screen (Phase 3)
    → Full user journey test (Phase 4)

RevenueCat webhook Cloud Function (Phase 1)
  → Premium gating (Phase 3)
    → Ad suppression for premium users (Phase 3)
      → Production readiness (Phase 4)
```

**Highest scheduling risk:** Content readiness. The methodology partner must have 4 complete weeks of content entered and reviewed before Phase 4 testing begins. Build buffer into the content entry schedule — do not assume it will be complete at the start of Phase 4.

---

## Monthly post-launch cadence

After production release, the following recurring tasks apply approximately monthly:

| Task | Owner | Notes |
|---|---|---|
| New content entry in admin panel | Methodology partner | Drafts in Google Docs first; enters via admin panel |
| Audio file upload and review | Methodology partner + Developer | Quality check before publishing |
| App update (bug fixes, UX improvements) | Developer | Based on Crashlytics, Analytics, and user feedback |
| Firebase cost review | Developer | Compare against budget alert thresholds |
| Analytics review | Developer + Methodology partner | Exercise correctness rates, drop-off points |
| User support inbox review | Developer | Respond to support emails, log recurring issues |

---