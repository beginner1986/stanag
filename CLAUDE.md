# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

STANAG 6001 English Learning App — a bilingual (Polish/English) Flutter app for Polish soldiers preparing for the STANAG 6001 Level 1 English exam. Targets Android (primary) and web (secondary). Freemium model with ads (free) and subscription (premium).

The Flutter app lives in `stanag_app/`. All commands below must be run from that directory.

## Commands

```bash
# Install dependencies
flutter pub get

# Generate localisations (required after editing .arb files)
flutter gen-l10n

# Analyse
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run on device/emulator (dev flavour)
flutter run --dart-define=FLAVOR=dev

# Build APK
flutter build apk --flavor dev -t lib/main.dart --dart-define=FLAVOR=dev
flutter build apk --flavor prod -t lib/main.dart --dart-define=FLAVOR=prod
```

## Architecture

### Flavours and Firebase configuration

The app has three flavours: `dev`, `staging`, `prod`. The active flavour is passed at build time via `--dart-define=FLAVOR=<flavour>`. `main.dart` reads it with `String.fromEnvironment('FLAVOR', defaultValue: 'dev')` and selects the matching `firebase_options_<flavour>.dart`.

The `firebase_options_*.dart` files contain secrets and are **not committed**. In CI they are restored from base64-encoded GitHub Actions secrets. Locally you must have your own copies.

All Firebase services are in region `europe-central2` (Warsaw). Cloud Functions must also explicitly set this region — the default is `us-central1`.

### State management — Riverpod

The app uses Riverpod. The root widget is wrapped in `ProviderScope`. Providers live in `lib/providers/`. Services are injected via providers (e.g., `authServiceProvider`, `userServiceProvider`) rather than instantiated directly in widgets.

### Authentication flow

On first launch, `main()` calls `AuthService.signInAnonymously()` before `runApp()`. This silently creates a Firebase anonymous UID. `UserService.createUserDocumentIfNeeded()` then writes the initial `users` document to Firestore (cache-first, server fallback).

The four user states are: `anonymous`, `registered_free`, `registered_premium`, `expired_premium`. Premium status is authoritative only via the JWT custom claim `is_premium` — set server-side by a Cloud Function webhook from RevenueCat. Never set premium state client-side.

When a user registers, the anonymous UID is preserved via `linkWithCredential()` — no data migration needed. If the email already exists, the app must catch the linking error, offer login, and manually merge progress.

### Localisation

UI strings are in `.arb` files at `lib/l10n/app_en.arb` (template) and `lib/l10n/app_pl.arb`. Run `flutter gen-l10n` after any `.arb` change to regenerate the `AppLocalizations` class. No hardcoded UI strings anywhere.

The active locale is managed by `LocaleNotifier` (in `lib/providers/locale_provider.dart`) and persisted to `SharedPreferences` under the key `interface_lang`. Exercise content is always in English regardless of locale.

Bilingual Firestore fields use `_pl` / `_en` suffixes (e.g., `title_pl`, `title_en`). The app reads the appropriate variant based on the current locale.

### Firestore data model

Two logical halves:
- **Content** (`levels`, `units`, `lessons`, `exercises`, `daily_motivations`) — public read, admin writes only via Cloud Functions using Admin SDK.
- **User data** (`users`, `user_progress`, `user_streaks`, `user_exercise_log`, `daily_plans`) — each user reads/writes only their own documents.

Premium-gated content (`mock_exams`) requires `request.auth.token.is_premium == true` in Security Rules.

**Important:** Security Rules for `user_progress`, `user_exercise_log`, and `daily_plans` use `resource.data.uid` for ownership checks, which is `null` on creates. Use `request.resource.data.uid` for create rules and `resource.data.uid` for read/update/delete rules.

Session writes (progress, streaks, daily plans) must be batched at the end of each lesson — not per-exercise — to stay within Firestore's free-tier write quota (~1,200 DAU ceiling).

### Current implementation status (Phase 1 in progress)

Completed:
- Firebase project setup with three flavours
- Anonymous sign-in on launch + initial `users` document creation
- Riverpod providers for auth and Firestore instances
- Localisation scaffold (PL/EN `.arb` files, locale persistence)
- CI pipeline (lint, test, build on PRs to `main`/`develop`)

In progress / not yet built:
- GoRouter navigation shell with auth-gated routes
- Registration, login, password reset screens
- RevenueCat integration and premium upgrade flow
- Cloud Function: RevenueCat webhook → JWT custom claim
