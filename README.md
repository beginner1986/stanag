# STANAG 6001 English Learning App

Bilingual (Polish/English) Flutter app for Polish soldiers preparing for the STANAG 6001 Level 1 English exam. Freemium model — ads for free users, subscription for premium.

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Android primary, web secondary) |
| State management | Riverpod 3 |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, FCM, Analytics, Crashlytics) |
| Payments | RevenueCat (planned) |
| Localisation | Flutter ARB / `flutter_localizations` (Polish + English) |

## Repository layout

```
stanag_app/       Flutter app
docs/             Specification and implementation plan
```

All Flutter commands must be run from `stanag_app/`.

## Flavours

| Flavour | Application ID | Firebase project |
|---|---|---|
| `dev` | `com.example.stanag_app.dev` | `stanag-dev` |
| `staging` | `com.example.stanag_app.staging` | `stanag-staging` |
| `prod` | `com.example.stanag_app` | `stanag-prod` |

## Local configuration (not committed)

Two sets of secret files must be present locally before building.

### 1. Firebase options (Dart)

Generate with the FlutterFire CLI from `stanag_app/`:

```bash
flutterfire configure --project=stanag-dev     --out=lib/firebase_options_dev.dart     --platforms=android,web
flutterfire configure --project=stanag-staging --out=lib/firebase_options_staging.dart --platforms=android,web
flutterfire configure --project=stanag-prod    --out=lib/firebase_options_prod.dart    --platforms=android,web
```

### 2. Android google-services.json (per flavour)

Download from each Firebase project's console (**Project settings → Your apps → google-services.json**) and place at:

```
stanag_app/android/app/src/dev/google-services.json
stanag_app/android/app/src/staging/google-services.json
stanag_app/android/app/src/prod/google-services.json
```

Each file must come from the matching Firebase project and contain only that flavour's application ID.

## Build & run

```bash
cd stanag_app

# Install dependencies
flutter pub get

# Generate localisations (required after editing .arb files)
flutter gen-l10n

# Run on device — dev flavour
flutter run --flavor dev --dart-define=FLAVOR=dev

# Build APK
flutter build apk --flavor dev  -t lib/main.dart --dart-define=FLAVOR=dev
flutter build apk --flavor prod -t lib/main.dart --dart-define=FLAVOR=prod
```

## Tests

```bash
cd stanag_app
flutter test
```

CI runs lint, tests, and a dev debug build on every PR to `main` or `develop`.
