# Premium Entitlement — Implementation Plan

> **Temporary document.** Remove when Phase 1 is finalized and all tasks are merged to main.

---

## Non-coding tasks (do these first — they unblock coding)

### A. RevenueCat setup
1. Create a RevenueCat account and two projects: `stanag-dev` and `stanag-prod`
2. In each project, connect to Google Play: upload a Google Play service account JSON (create one in Google Cloud Console with `androidpublisher` scope)
3. Create an **Entitlement**: `premium`
4. Create a **Product** matching the Google Play subscription ID (once Play Console product exists — see B)
5. Create an **Offering** with one package (monthly subscription) linked to that product
6. Note down the **RevenueCat Public API key** for dev and prod (used in Flutter SDK)
7. Note down the **RevenueCat Webhook secret** (used in Cloud Function to validate request authenticity)

### B. Google Play Console
1. Create a subscription product (e.g. `stanag_premium_monthly`), price 20–40 PLN, billing period monthly
2. Set up a base plan with auto-renewal
3. Link the product ID back to RevenueCat (step A.4 above)

### C. Firebase Cloud Functions project init
1. Run `firebase init functions` in the repo root — creates `functions/` directory with Node.js scaffold
2. Set the default region to `europe-central2` in `functions/index.js` (critical — default is `us-central1`)

---

## Coding track 1 — Cloud Function (webhook)

### D. `functions/index.js` — RevenueCat webhook handler
- HTTPS-triggered function, region `europe-central2`
- Validates `Authorization: Bearer <secret>` header against env secret
- Handles RevenueCat event types:
  - `INITIAL_PURCHASE`, `RENEWAL` → set `is_premium: true`, `premium_until: <expiry>`
  - `CANCELLATION`, `EXPIRATION`, `BILLING_ISSUE` → set `is_premium: false`, clear `premium_until`
- Calls `admin.auth().setCustomUserClaims(uid, { is_premium, premium_until })` (server-side only, never client)
- Writes matching fields to `users/{uid}` Firestore document
- Returns 200 immediately (RevenueCat retries on non-2xx)

### E. Configure webhook in RevenueCat dashboard
- Paste the Cloud Function HTTPS trigger URL
- Set the webhook secret (matches env variable in the function)

### F. Deploy function
- `firebase deploy --only functions` to `stanag-dev`, verify in Firebase console logs

---

## Coding track 2 — Flutter app ✅

### G. ~~Add `purchases_flutter` package~~ ✅
- ~~`flutter pub add purchases_flutter` from `stanag_app/`~~ — added v10.0.1

### H. ~~RevenueCat initialization in `main.dart`~~ ✅
- ~~After Firebase init and anonymous sign-in, call:~~
  ```dart
  await Purchases.setLogLevel(LogLevel.debug); // dev only
  final config = PurchasesConfiguration('<revenuecat_api_key>')
    ..appUserID = FirebaseAuth.instance.currentUser!.uid;
  await Purchases.configure(config);
  ```
- ~~API key must be flavor-specific — store it as a `--dart-define` build arg or in a flavor config file (same pattern as Firebase options)~~ — `--dart-define=REVENUECAT_API_KEY`, skipped on web and when key is empty
- ~~This ties the RevenueCat App User ID to the Firebase UID so the webhook can identify the user~~

### I. ~~`lib/services/purchase_service.dart`~~ ✅
- ~~`getOfferings()` → `Future<Offerings>` (fetches available packages + pricing)~~
- ~~`purchasePackage(Package)` → `Future<CustomerInfo>` (triggers Play Billing sheet)~~ — returns `Future<void>`; uses v10 `Purchases.purchase(PurchaseParams.package(...))`
- ~~`restorePurchases()` → `Future<CustomerInfo>` (for users who reinstall)~~ — returns `Future<void>`

### J. ~~`lib/providers/purchase_provider.dart`~~ ✅
- ~~`purchaseServiceProvider` — plain `Provider<PurchaseService>`~~
- ~~`offeringsProvider` — `FutureProvider<Offerings>` (loads once on startup, drives UpgradeScreen)~~

### K. ~~`lib/screens/upgrade_screen.dart`~~ ✅
- ~~Feature comparison list (free vs premium — from spec section 7.1/7.2)~~
- ~~Price loaded from `offeringsProvider` (real Play Store price, localised by Play)~~
- ~~"Subscribe" button → `purchasePackage()` → on success → `AuthService.refreshToken()` → Navigator pop~~
- ~~"Restore purchase" text button → `restorePurchases()` → `refreshToken()`~~
- ~~Loading spinner and error snackbar states~~
- ~~All strings in `.arb` files (EN + PL)~~

### L. ~~Add `.arb` strings~~ ✅
- ~~`upgradeScreenTitle`, `upgradeScreenSubtitle`, premium feature list items, CTA button label, restore label, success/error messages — in both `app_en.arb` and `app_pl.arb`~~

### M. ~~Wire navigation~~ ✅
- ~~Add `/upgrade` route to `router_provider.dart`~~
- ~~Add "Upgrade to Premium" button to `SettingsScreen` for `registered_free` and `expired_premium` states (already shows account type — add button below it)~~

### N. Tests (partial) ⚠️
- ~~Unit test `PurchaseService` methods (mock `Purchases` static calls using mocktail or a thin wrapper)~~ — tested via interface mock; no separate service unit test (thin wrapper has no logic to test)
- ~~Widget test `UpgradeScreen`: renders offering price, tapping subscribe triggers service, success state navigates away~~ — 8 tests covering all paths
- Unit test Cloud Function webhook handler (mock Firebase Admin SDK, assert correct claims set per event type) — pending Cloud Function track

---

## Integration verification (last)

### O. End-to-end test in dev
1. Run app on Android emulator with `dev` flavor
2. Complete a purchase using a Google Play test account (sandbox)
3. Verify RevenueCat dashboard shows the purchase
4. Verify Cloud Function log shows webhook received and custom claim set
5. Verify app UI transitions to `registered_premium` without restart (token refresh chain)
6. Simulate subscription expiry in RevenueCat → verify app drops back to `registered_free`

---

## Dependency order

```
A (RevenueCat account) ─┬──→ H (SDK init) ──→ I,J,K (Flutter code)
B (Play Console)        ─┘
C (Functions init)      ──→ D (webhook code) ──→ E (configure in RC) ──→ F (deploy)
                              ↓
                         O (end-to-end test) ← requires A+B+F+K all done
```

The Flutter UI (tracks G–M) and the Cloud Function (track D–F) can be built in parallel. RevenueCat and Play Console setup (A–B) are the earliest critical path — they are the only things that cannot be done without external accounts.
