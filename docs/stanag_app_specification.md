# STANAG 6001 English Learning App — Product Specification

**Version:** 1.0  
**Date:** April 2026  
**Status:** Pre-implementation  

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Target Audience](#2-target-audience)
3. [Platform and Distribution](#3-platform-and-distribution)
4. [Tech Stack](#4-tech-stack)
5. [Data Schema](#5-data-schema)
6. [Authentication and Security](#6-authentication-and-security)
7. [Feature Specification](#7-feature-specification)
8. [User Flows](#8-user-flows)
9. [Monetisation](#9-monetisation)
10. [Content Structure](#10-content-structure)
11. [Admin Panel](#11-admin-panel)
12. [Localisation](#12-localisation)
13. [Offline Support](#13-offline-support)
14. [Analytics](#14-analytics)
15. [Infrastructure and Costs](#15-infrastructure-and-costs)
16. [Implementation Plan](#16-implementation-plan)
17. [Future Versions](#17-future-versions)

---

## 1. Product Overview

A bilingual (Polish/English) mobile-first application supporting Polish professional soldiers in preparing for the **STANAG 6001 English language exam at Level 1**. The app delivers a structured daily learning experience based on spaced repetition, daily motivation, and progress tracking.

The v1 product is focused exclusively on STANAG 6001 Level 1 preparation. Level 2 is planned for v2. The app is available on Android (primary) and via a web browser (secondary). It operates on a freemium model — free access supported by ads, with a paid premium tier unlocking additional features.

### Core principles

- **Daily habit first.** The app is built around a daily session. Every design decision serves retention and streak maintenance.
- **Military-appropriate tone.** UI is disciplined, clean, and progress-driven. No childish gamification.
- **Solo learning.** No social or competitive features in v1. Aggregated statistics comparison is planned for v2.
- **Non-technical content management.** The methodology partner can add and edit all content without touching code.
- **Data minimalism.** Only the data necessary for the product is collected. No unnecessary personal information.

---

## 2. Target Audience

**Primary users:** Polish professional soldiers aged 20–40 who need or want to pass the STANAG 6001 Level 1 English exam.

**Acquisition:** Individual and self-motivated. No institutional push mechanism in v1.

**Usage context:**
- 80–90% online usage (barracks, home, mobile data)
- 10–20% in field conditions with poor or no internet connectivity

**Device assumptions:** Personal Android smartphones. Not issued military devices. Google Play Store access assumed.

**Language:** The user interface is available in Polish and English, switchable at any time. Exercise content is always in English.

---

## 3. Platform and Distribution

| Platform | Details |
|---|---|
| Android app | Primary. Distributed via Google Play Store (public listing). |
| Web browser | Secondary. Flutter web build deployed to Firebase Hosting with a custom domain. |
| iOS | Not in scope for v1. |

The Android app and web version share the same Flutter codebase. Bug fixes and feature releases ship to both simultaneously.

---

## 4. Tech Stack

| Layer | Technology | Rationale |
|---|---|---|
| Mobile + web | Flutter (Dart) | Single codebase for Android and web; native performance |
| Authentication | Firebase Auth (EU) | Email/password + anonymous auth; account linking |
| Database | Firestore (europe-west1) | EU data residency; offline persistence built in |
| File storage | Firebase Storage (EU) | Audio files for listening exercises |
| Push notifications | Firebase Cloud Messaging | Daily reminder notifications |
| Subscriptions | RevenueCat | Manages Google Play Billing and entitlement state |
| Ads | Google AdMob | Non-intrusive ads for free tier; filtered content |
| Analytics | Firebase Analytics + Crashlytics | UX and content quality improvement |
| State management | Riverpod | Clean, testable architecture for a single-developer team |
| Navigation | GoRouter | Auth-gated routing |
| Localisation | flutter_localizations + intl | PL/EN switchable UI strings |
| Audio playback | just_audio | TTS and recorded audio exercise delivery |
| Cloud Functions | Firebase Cloud Functions (Node.js) | Server-side logic: daily plan generation, premium webhooks, admin writes |

### Firebase project configuration

- **Plan:** Blaze (pay-as-you-go). Required for Firebase Storage access.
- **Region:** `europe-west1` (Belgium). Set at project creation — cannot be changed.
- **Budget alert:** $5/month configured from day one.
- **Flavours:** Three Firebase projects — `dev`, `staging`, `prod`. Flutter flavour configuration connects each build to its project.

---

## 5. Data Schema

The Firestore schema is divided into two logical halves: **content** (admin-managed) and **user data** (app-generated).

### 5.1 Content collections

#### `levels`
Top-level course container. One document per STANAG level.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | e.g. `stanag_l1` |
| `code` | string | Short identifier used in app logic |
| `title_pl` | string | Display name in Polish |
| `title_en` | string | Display name in English |
| `sort_order` | int | Sequence when multiple levels exist |
| `is_published` | bool | Controls visibility to users |

#### `units`
Thematic blocks within a level. Expect 10–20 units per level.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | Auto-generated |
| `level_id` | string (FK) | Parent level |
| `sort_order` | int | Sequence within the level |
| `title_pl` | string | Unit title in Polish |
| `title_en` | string | Unit title in English |
| `skill_focus` | string | Controlled vocabulary: `vocabulary`, `grammar`, `listening`, `reading`, `mixed` |

#### `lessons`
A single daily session within a unit.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | Auto-generated |
| `unit_id` | string (FK) | Parent unit |
| `sort_order` | int | Sequence within the unit |
| `type` | string | e.g. `standard`, `review`, `unit_test` |
| `title_pl` | string | Lesson title in Polish |
| `title_en` | string | Lesson title in English |
| `xp_reward` | int | XP awarded on completion |
| `is_published` | bool | Controls visibility to users |

#### `exercises`
Individual tasks within a lesson.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | Auto-generated |
| `lesson_id` | string (FK) | Parent lesson |
| `type` | string | `vocabulary_flashcard`, `multiple_choice`, `gap_fill`, `listening_comprehension`, `true_false` |
| `sort_order` | int | Sequence within the lesson |
| `prompt_pl` | string | Instruction in Polish |
| `prompt_en` | string | Instruction in English |
| `audio_url` | string | Firebase Storage URL for audio file |
| `audio_source` | string | `tts` or `recorded` |
| `options` | JSON | Exercise-type-specific option structure |
| `correct_answer` | string | Answer key |
| `explanation_pl` | string | Post-answer explanation in Polish |
| `explanation_en` | string | Post-answer explanation in English |
| `difficulty` | int | 1–5 scale; agreed definition required before content entry begins |

#### `daily_motivations`
One motivational message per day of the course.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | Auto-generated |
| `level_id` | string (FK) | Associated level |
| `day_number` | int | Day of the course (not calendar date) |
| `text_pl` | string | Quote in Polish |
| `text_en` | string | Quote in English |
| `author` | string | Attribution (optional) |

### 5.2 User collections

#### `users`
One document per user. Created on first app launch with anonymous UID.

| Field | Type | Description |
|---|---|---|
| `uid` | string (PK) | Firebase Auth UID |
| `email` | string | Set on registration; null for anonymous |
| `display_name` | string | Optional; set on registration |
| `interface_lang` | string | `pl` or `en`; detected from device locale on first launch |
| `created_at` | timestamp | First launch time |
| `is_anonymous` | bool | `true` until account linked |
| `is_premium` | bool | Set by Cloud Function webhook only |
| `premium_until` | timestamp | Subscription expiry |
| `current_level_id` | string (FK) | Active STANAG level |

#### `user_progress`
One document per completed lesson per user.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | Auto-generated |
| `uid` | string (FK) | User |
| `lesson_id` | string (FK) | Completed lesson |
| `completed_at` | timestamp | Completion time |
| `score_pct` | int | Score as percentage (0–100) |
| `xp_earned` | int | XP awarded this session |
| `attempts` | int | Number of attempts at this lesson |

#### `user_streaks`
One document per user. Read and written every session.

| Field | Type | Description |
|---|---|---|
| `uid` | string (PK) | User |
| `current_streak` | int | Days in current streak |
| `longest_streak` | int | All-time best streak |
| `last_active_date` | timestamp | Date of last completed session |
| `freeze_tokens` | int | Streak freeze tokens (future feature) |

#### `user_exercise_log`
One document per exercise answer. Primary input for the spaced repetition algorithm.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | Auto-generated |
| `uid` | string (FK) | User |
| `exercise_id` | string (FK) | Answered exercise |
| `answered_at` | timestamp | Answer time |
| `is_correct` | bool | Whether the answer was correct |
| `response_time_ms` | int | Time taken to answer in milliseconds |
| `repetition_count` | int | How many times this exercise has been seen |
| `next_review_at` | timestamp | Calculated next review date (SR algorithm output) |

#### `daily_plans`
One document per user per day.

| Field | Type | Description |
|---|---|---|
| `id` | string (PK) | Auto-generated |
| `uid` | string (FK) | User |
| `level_id` | string (FK) | Active level |
| `plan_date` | date | Calendar date of the plan |
| `lesson_ids` | JSON | Ordered list of lesson IDs for the day |
| `is_completed` | bool | Whether the day's plan is fully done |
| `total_xp_earned` | int | XP earned across all sessions that day |

---

## 6. Authentication and Security

### 6.1 User states

Every user is always in exactly one of four states:

| State | Description |
|---|---|
| `anonymous` | First launch. Firebase anonymous UID assigned. Progress stored locally and in Firestore. |
| `registered_free` | Email/password account created. `is_anonymous: false`, `is_premium: false`. |
| `registered_premium` | Active RevenueCat subscription. `is_premium: true`, `premium_until` set. |
| `expired_premium` | Subscription lapsed. Treated as free tier. |

### 6.2 Anonymous to registered migration

Firebase anonymous auth UID is preserved through account creation via `linkWithCredential()`. The UID does not change — all Firestore data written under the anonymous UID is automatically owned by the registered account. No data migration required.

**Edge case:** If the email address is already registered (user previously created an account), the app catches the linking error, offers login, and manually merges day 1 progress into the existing account.

### 6.3 JWT and custom claims

Firebase Auth issues a short-lived ID token (JWT, 1-hour expiry) and a long-lived refresh token. The Flutter SDK manages both automatically.

Premium status is stored as a **custom JWT claim** (`is_premium: true`) set by a Cloud Function webhook triggered by RevenueCat. This is the authoritative source for premium gating — not the Firestore `users` document. Security Rules enforce access using `request.auth.token.is_premium`.

```javascript
// Cloud Function — RevenueCat webhook
await admin.auth().setCustomUserClaims(uid, {
  is_premium: true,
  premium_until: expiryTimestamp
});
```

### 6.4 Firestore Security Rules

```javascript
// Content — public read, admin write via Cloud Function only
match /levels/{id}    { allow read: if true; }
match /units/{id}     { allow read: if true; }
match /lessons/{id}   { allow read: if true; }
match /exercises/{id} { allow read: if true; }

// User data — each user reads and writes only their own documents
match /users/{uid} {
  allow read, write: if request.auth.uid == uid;
}
match /user_progress/{docId} {
  allow read, write: if request.auth.uid == resource.data.uid;
}
match /user_streaks/{uid} {
  allow read, write: if request.auth.uid == uid;
}
match /user_exercise_log/{docId} {
  allow read, write: if request.auth.uid == resource.data.uid;
}
match /daily_plans/{docId} {
  allow read, write: if request.auth.uid == resource.data.uid;
}

// Premium-gated content
match /mock_exams/{id} {
  allow read: if request.auth.token.is_premium == true;
}
```

Admin writes always go through Cloud Functions using the Admin SDK, which bypasses Security Rules. The content editor never has direct Firestore write access.

### 6.5 Data residency and privacy

- All Firebase services configured in `europe-west1` (Belgium, EU).
- Minimum data collection: email address and display name only. No full name, rank, unit, or other military-identifying information required.
- RODO-compliant privacy policy required before launch, written in Polish and English.
- Refresh token inactivity expiry set to 90 days in Firebase Auth console.

---

## 7. Feature Specification

### 7.1 Free tier features

- Full day 1 content without account creation
- Anonymous session with local progress storage
- Sign-up prompt on day 1 result screen (after results are shown)
- Guest mode — continue without account (progress lost if app uninstalled)
- 10 exercises per day limit
- Streak counter with flexible catch-up (one missed day allowed before streak breaks)
- Basic XP and overall progress tracking
- Unit and week completion badges
- Overall STANAG Level 1 progress bar
- Daily motivational quotes (PL/EN)
- Daily push notification reminder (configurable time)
- Audio pronunciation for exercises (TTS and recorded)
- End-of-unit self-check quizzes
- Completion certificate (PDF, downloadable) on course completion
- Infinite spaced repetition review mode on course completion
- Exam scheduling suggestion on course completion
- Ads shown between sessions (interstitial) and on home screen (banner)
- PL/EN interface language switcher
- Email-based user support

### 7.2 Premium tier features

All free tier features, plus:

- Unlimited daily exercises
- No ads
- Offline content packs (pre-downloaded for field use)
- Detailed per-skill analytics: vocabulary, grammar, listening scores over time
- Weak area identification and targeted review suggestions
- Timed mock exam — reading and listening modules (auto-graded)
- Writing module — submitted for async tutor review *(v1.5)*
- Tutor feedback delivered in-app *(v1.5)*
- Priority tutor turnaround *(v1.5)*
- Level 2 course access *(v2)*

### 7.3 Exercise types

| Type | Description | Widget |
|---|---|---|
| `vocabulary_flashcard` | Word shown with audio; user rates recall | Flip card with audio button |
| `multiple_choice` | Question with 4 options | Tap-to-select grid |
| `gap_fill` | Sentence with blank; word bank provided | Tap-to-insert word tokens |
| `listening_comprehension` | Audio clip followed by question and options | Audio player + multiple choice |
| `true_false` | Statement; user selects true or false | Two-button interface |

All exercise types show correct/incorrect animated feedback and an explanation after answering.

### 7.4 Course completion flow

When a user completes all lessons in STANAG Level 1, they are presented with three options:

1. **Schedule the real exam** — link to information about STANAG exam booking.
2. **Infinite review mode** — spaced repetition algorithm runs indefinitely over completed content.
3. **Move to Level 2** — upsell to premium; Level 2 course access unlocked. *(v2)*

---

## 8. User Flows

### 8.1 First launch and day 1

```
App opens
  → Anonymous Firebase UID created silently
  → USERS document created with is_anonymous: true
  → Onboarding screen (language selection, brief app explanation)
  → Day 1 lesson begins immediately — no sign-up required
  → User completes up to 10 exercises
  → Session result screen: score, XP earned, streak day 1 badge, day 2 preview
  → Sign-up prompt card shown below results
      → Sign up: email + password → anonymous UID linked → registered_free
      → Continue as guest: progress stored locally, warning shown
```

### 8.2 Daily returning user

```
App opens
  → Auth state checked → user identified
  → Home screen: today's plan card, streak counter, daily motivation quote
  → Tap "Start today's lesson"
  → Lesson player: progress bar, exercise sequence, per-answer feedback
  → Session result screen: score, XP, streak update
  → [Free user] Interstitial ad shown
  → Return to home screen
```

### 8.3 Premium upgrade

```
User hits 10-exercise daily limit
  → Upgrade prompt shown with feature list and pricing
  → Tap "Upgrade"
  → RevenueCat payment sheet (Google Play Billing)
  → Purchase confirmed
  → RevenueCat webhook → Cloud Function → custom JWT claim set → USERS updated
  → User's app detects claim on next token refresh (force refresh triggered)
  → Premium features unlocked immediately
```

### 8.4 Account recovery

```
Login screen → "Forgot password"
  → Enter email address
  → Firebase sends reset email (Polish copy, app branding)
  → User resets password
  → Logs in with new password
```

---

## 9. Monetisation

### 9.1 Model

Freemium with two revenue streams:

- **Ads (free tier):** Google AdMob. Interstitial between sessions; banner on home screen. Premium users see no ads.
- **Subscription (premium tier):** Monthly recurring subscription via Google Play Billing, managed by RevenueCat.

### 9.2 Pricing

Target price range: **20–40 PLN/month**. Final pricing to be confirmed before launch based on market research.

### 9.3 Ad configuration

AdMob content filters must exclude the following categories before launch:

- Gambling and betting
- Alcohol and tobacco
- Political content
- Adult content

### 9.4 Subscription management

RevenueCat manages the full subscription lifecycle: purchase, renewal, cancellation, and expiry. Entitlement state is propagated server-side via webhook to a Cloud Function, which sets the JWT custom claim and updates the `users` Firestore document. The client never sets its own premium status.

---

## 10. Content Structure

### 10.1 Course scope

STANAG 6001 Level 1 corresponds approximately to A2. Target skills:

- Understanding simple spoken English (greetings, instructions, numbers, phonetic alphabet)
- Giving basic personal information
- Reading short notices and simple written messages
- Writing simple messages and forms

### 10.2 Course duration

3–6 months of daily content at 10–15 exercises per day. Estimated 270–540 lesson sessions total.

### 10.3 Content ownership

All content is created by the methodology partner and/or outsourced collaborators. Full content ownership of product owners.

### 10.4 Audio

Exercises use a mix of TTS-generated and professionally recorded audio. The `audio_source` field on each exercise indicates which, allowing quality filtering in analytics. Audio files are stored in Firebase Storage.

### 10.5 Content update cadence

New content and corrections published approximately monthly via the admin panel. No app update required for content changes.

### 10.6 Controlled vocabularies

The following field values must be agreed with the methodology partner before content entry begins:

**`skill_focus` on units:** `vocabulary`, `grammar`, `listening`, `reading`, `mixed`

**`difficulty` on exercises:** 1–5 integer scale. Definition per level must be agreed and documented before content entry.

**`type` on exercises:** `vocabulary_flashcard`, `multiple_choice`, `gap_fill`, `listening_comprehension`, `true_false`

---

## 11. Admin Panel

A Flutter web application, password-protected behind a separate Firebase Auth admin role. The admin panel never writes to Firestore directly — all writes go through Cloud Functions using the Admin SDK.

### 11.1 Features

- Create, edit, and reorder levels and units
- Create, edit, and reorder lessons within units
- Create, edit, and reorder exercises within lessons (all five exercise types)
- Upload audio files with TTS/recorded toggle
- Publish and unpublish lessons and levels
- Preview mode — view content as a user would before publishing
- Manage daily motivational quotes (PL + EN) per day number

### 11.2 Access

- Separate login from the main app
- Admin role assigned manually in Firebase Auth via Admin SDK
- No self-registration; admin accounts created by the developer

---

## 12. Localisation

The app interface is available in Polish and English, switchable at any time from Settings. The user's preference is stored in `users.interface_lang` in Firestore and in `SharedPreferences` for offline access.

**All UI strings** are stored in `.arb` files from day one. No hardcoded strings anywhere in the app.

**Exercise content** is always in English regardless of interface language setting.

**Bilingual fields in Firestore:** All content documents have `_pl` and `_en` string variants for user-facing text. The app reads the appropriate variant based on the current interface language.

**Motivational content** and notification copy are stored in Firestore with both language variants, not hardcoded.

---

## 13. Offline Support

### 13.1 Strategy

The app targets 80% online usage. Full offline-first architecture is not required. The strategy is smart pre-fetching of today's content.

### 13.2 Implementation

- Firestore offline persistence enabled — lesson content and user progress cached automatically.
- Audio files for today's lesson pre-fetched on app open while on Wi-Fi. Stored in local file cache.
- Once a user downloads an audio file, it is never re-downloaded — aggressive local caching to minimise Firebase Storage egress costs.
- Premium users can manually trigger a download of a full offline content pack (multiple days of lessons and audio).
- On reconnection after offline session: Firestore pending writes sync automatically; no manual reconciliation needed.

### 13.3 Anonymous users offline

Day 1 progress for anonymous users is stored on the device via Firestore's offline persistence under the anonymous UID. On sign-up, the anonymous UID is linked to the new account and all data syncs.

---

## 14. Analytics

Firebase Analytics events are instrumented for all key user actions from day one. Events feed into content quality review and UX improvement cycles.

### 14.1 Key events

| Event | Purpose |
|---|---|
| `session_start` | Daily active user tracking |
| `exercise_answered` | Correctness, response time, exercise ID |
| `lesson_completed` | Score, XP, lesson ID, attempt count |
| `streak_updated` | Streak length at update time |
| `signup_prompted` | Track prompt exposure |
| `signup_completed` | Funnel conversion |
| `upgrade_prompted` | Track paywall exposure |
| `upgrade_completed` | Premium conversion |
| `daily_limit_hit` | Free tier friction point |
| `language_switched` | PL/EN preference tracking |
| `notification_opened` | Push notification effectiveness |

### 14.2 Content quality signals

- Exercise correctness rate by `exercise_id` — identifies poorly worded or too-difficult exercises
- Average `response_time_ms` by exercise — identifies confusing prompts
- Lesson drop-off rate — identifies sessions that lose users before completion
- Audio source (`tts` vs `recorded`) vs correctness rate — validates audio quality investment

### 14.3 Crashlytics

Enabled from day one. All crashes attributed to app version, device model, and OS version. Reviewed after every release.

---

## 15. Infrastructure and Costs

### 15.1 Firebase Blaze plan — free quota limits

| Resource | Free quota | Safe user ceiling |
|---|---|---|
| Firestore reads | 50,000/day | ~3,000 DAU |
| Firestore writes | 20,000/day | ~1,200 DAU |
| Firestore storage | 1 GB | ~5,000 users (text data only) |
| Firebase Storage | Google Cloud Always Free tier | ~1 GB/month egress free |
| Firebase Auth (email) | 50,000 MAU | Ample for v1 |
| FCM | Unlimited | — |
| Firebase Analytics | Unlimited | — |

The binding constraint is **Firestore writes at ~1,200 daily active users**. Mitigation: batch all session writes at end of lesson rather than per-exercise.

### 15.2 Cost at scale

At 2,000 daily active users (beyond v1 launch expectations):

- Firestore write overage: ~$1–2/day (~$30–60/month)
- Firebase Storage egress (with caching): <$10/month
- Total estimated infrastructure cost: <$100/month

By this user volume, AdMob and premium subscription revenue should substantially exceed infrastructure cost.

### 15.3 Operational responsibilities

All Firebase costs are managed by the product owners. A $5/month budget alert is configured from day one. Monthly cost review aligned with content update cadence.

---

## 16. Implementation Plan

### Phase 0 — Project foundation

- Firebase project setup (Blaze, europe-west1, budget alert)
- Flutter project with dev/staging/prod flavours
- Core package integration and configuration
- CI/CD pipeline (GitHub Actions)
- Localisation scaffold (PL/EN .arb files)

### Phase 1 — Authentication and user shell

- Anonymous auth on first launch
- Email/password registration with anonymous UID linking
- Email-already-exists edge case handling
- Login and password reset screens
- GoRouter with auth-gated routes
- Bottom navigation shell: Home, Progress, Settings
- RevenueCat integration and premium upgrade flow
- Cloud Function: premium webhook → JWT custom claim

### Phase 2 — Content engine and lesson player

- Firestore seeding with agreed schema
- Flutter web admin panel (full CRUD for all content types)
- Admin panel: audio upload, publish/unpublish, preview mode
- Five exercise widget implementations
- Lesson player with progress bar and session result screen
- Sign-up prompt on day 1 result screen
- Batch write of session data to Firestore
- Audio pre-caching for offline use
- Firestore offline persistence enabled

### Phase 3 — Daily loop, progress and motivation

- Cloud Function: daily plan generator (runs at midnight)
- Home screen: today's plan, streak, motivation quote
- Free tier daily exercise cap (10/day) with upgrade prompt
- Leitner box spaced repetition algorithm
- Review mode for completed content
- Streak logic with flexible catch-up
- Streak milestone celebrations (day 7, 30, 60, 100)
- Daily FCM push notifications
- Progress screen: level completion, unit breakdown, per-skill analytics (premium)
- Course completion screen: three-branch flow
- AdMob integration with content filters

### Phase 4 — Polish, testing and launch

- Minimum 4 weeks of content populated by methodology partner
- Audio quality review
- Motivational quotes populated (days 1–30, PL + EN)
- Unit tests: SR algorithm, streak logic, daily plan generator
- Widget tests: all five exercise types
- End-to-end test: full user journey
- Real device testing (minimum 3 Android devices)
- Web browser testing (Chrome, Firefox, Safari mobile)
- Offline mode testing
- RODO privacy policy and terms of service (PL + EN)
- Cookie consent banner for web
- Google Play listing (PL + EN), store assets, screenshots
- Internal test → closed beta (10–20 soldiers) → open beta → production
- Firebase Hosting deployment with custom domain
- Email support inbox setup
- Analytics event verification

---

## 17. Future Versions

### v1.5 — Tutor workflow

- Mock exam writing module: user submits written response in-app
- Tutor back-office dashboard: queue of pending submissions
- Tutor posts score and written feedback in-app
- Push notification to user when result is posted
- Speaking module conducted via external video tool (Teams/Zoom); result entered manually by tutor

### v2 — STANAG Level 2 and social features

- STANAG 6001 Level 2 full course (all content and exercise types)
- Level 2 unlocked as premium feature
- Anonymised user statistics comparison (opt-in): how a user's progress compares to all users at the same course day
- Streak freeze tokens
- iOS app

---

## Appendix A — Exercise `options` JSON structure by type

### `vocabulary_flashcard`
```json
{
  "word": "barracks",
  "translation_pl": "koszary",
  "example_sentence": "The soldiers returned to the barracks after training."
}
```

### `multiple_choice`
```json
{
  "question": "What does NATO stand for?",
  "options": [
    "North Atlantic Treaty Organization",
    "National Army Training Operations",
    "Northern Alliance Treaty Organization",
    "North American Treaty Operations"
  ]
}
```

### `gap_fill`
```json
{
  "sentence": "Please report to the ___ at 0800.",
  "word_bank": ["barracks", "canteen", "office", "gate"],
  "blank_index": 4
}
```

### `listening_comprehension`
```json
{
  "question": "What time does the soldier need to report?",
  "options": ["0600", "0700", "0800", "0900"]
}
```

### `true_false`
```json
{
  "statement": "NATO was founded in 1949."
}
```

---

## Appendix B — Glossary

| Term | Definition |
|---|---|
| STANAG 6001 | NATO Standardization Agreement defining language proficiency levels for military personnel |
| Level 1 | Basic survival English; approximately CEFR A2 |
| SR | Spaced repetition — a learning technique that schedules review at increasing intervals |
| Leitner box | A simple SR algorithm using difficulty-based scheduling buckets |
| MAU | Monthly active user |
| DAU | Daily active user |
| RODO | Polish data protection regulation (equivalent to GDPR) |
| TTS | Text-to-speech — AI-generated audio |
| FCM | Firebase Cloud Messaging — push notification service |
| JWT | JSON Web Token — the signed token Firebase uses for auth |
| RevenueCat | Third-party subscription management SDK |
| AdMob | Google's mobile advertising platform |
| Blaze | Firebase's pay-as-you-go pricing plan |
| europe-west1 | Google Cloud region in Belgium; used for EU data residency |

---

*This document reflects decisions made as of April 2026. It should be updated when significant product decisions change.*
