import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/providers/purchase_provider.dart';
import 'package:stanag_app/screens/upgrade_screen.dart';
import 'package:stanag_app/services/auth_service.dart';
import 'package:stanag_app/services/purchase_service.dart';
import '../mocks/service_mocks.dart';

class FakePackage extends Fake implements Package {}

// ── Minimal fake offerings ──────────────────────────────────────────────────

const _fakeProduct = StoreProduct(
  'stanag_premium_monthly',
  'STANAG Premium subscription',
  'STANAG Premium',
  29.99,
  '29,99 zł',
  'PLN',
);

const _fakeContext = PresentedOfferingContext('default', null, null);

const _fakePackage = Package(
  r'$rc_monthly',
  PackageType.monthly,
  _fakeProduct,
  _fakeContext,
);

const _fakeOffering = Offering(
  'default',
  'Default offering',
  {},
  [_fakePackage],
  monthly: _fakePackage,
);

const _fakeOfferings = Offerings({'default': _fakeOffering}, current: _fakeOffering);

// ── Test wrapper ─────────────────────────────────────────────────────────────

enum _OfferingsState { data, loading, error }

Widget _wrap({
  required MockPurchaseService purchaseService,
  required MockAuthService authService,
  _OfferingsState offeringsState = _OfferingsState.data,
}) {
  final router = GoRouter(
    initialLocation: '/upgrade',
    routes: [
      GoRoute(path: '/upgrade', builder: (_, _) => const UpgradeScreen()),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
    ],
  );

  Future<Offerings> offeringsOverride() async {
    return switch (offeringsState) {
      _OfferingsState.data => _fakeOfferings,
      _OfferingsState.error => throw Exception('network error'),
      _OfferingsState.loading => Completer<Offerings>().future,
    };
  }

  return ProviderScope(
    overrides: [
      purchaseServiceProvider.overrideWithValue(purchaseService),
      authServiceProvider.overrideWithValue(authService),
      offeringsProvider.overrideWith((_) => offeringsOverride()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockPurchaseService mockPurchaseService;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FakePackage());
  });

  setUp(() {
    mockPurchaseService = MockPurchaseService();
    mockAuthService = MockAuthService();
    SharedPreferences.setMockInitialValues({});
  });

  // ── Loading state ───────────────────────────────────────────────────────────

  testWidgets('shows loading indicator while offerings are loading',
      (tester) async {
    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
      offeringsState: _OfferingsState.loading,
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ── Error state ─────────────────────────────────────────────────────────────

  testWidgets('shows error message when offerings fail to load',
      (tester) async {
    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
      offeringsState: _OfferingsState.error,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Purchase failed'), findsOneWidget);
  });

  // ── Data state ──────────────────────────────────────────────────────────────

  testWidgets('renders feature tiles and price when offerings are available',
      (tester) async {
    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Timed Mock Exams'), findsOneWidget);
    expect(find.text('Unlimited Exercises'), findsOneWidget);
    expect(find.text('Ad-Free'), findsOneWidget);
    expect(find.text('Offline Content Packs'), findsOneWidget);
    expect(find.textContaining('29,99 zł'), findsOneWidget);
    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.text('Restore purchase'), findsOneWidget);
  });

  // ── Subscribe ───────────────────────────────────────────────────────────────

  testWidgets('subscribe button calls purchasePackage and refreshToken',
      (tester) async {
    when(() => mockPurchaseService.purchasePackage(any()))
        .thenAnswer((_) async {});
    when(() => mockAuthService.refreshToken()).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    verify(() => mockPurchaseService.purchasePackage(any())).called(1);
    verify(() => mockAuthService.refreshToken()).called(1);
  });

  testWidgets('subscribe shows error snackbar on non-cancellation failure',
      (tester) async {
    when(() => mockPurchaseService.purchasePackage(any()))
        .thenThrow(PurchasesError(PurchasesErrorCode.storeProblemError, '', '', ''));

    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Purchase failed'), findsOneWidget);
    verifyNever(() => mockAuthService.refreshToken());
  });

  testWidgets('subscribe silently ignores cancellation error', (tester) async {
    when(() => mockPurchaseService.purchasePackage(any())).thenThrow(
      PurchasesError(PurchasesErrorCode.purchaseCancelledError, '', '', ''),
    );

    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    verifyNever(() => mockAuthService.refreshToken());
  });

  // ── Restore ─────────────────────────────────────────────────────────────────

  testWidgets('restore calls restorePurchases and refreshToken', (tester) async {
    when(() => mockPurchaseService.restorePurchases()).thenAnswer((_) async {});
    when(() => mockAuthService.refreshToken()).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore purchase'));
    await tester.pumpAndSettle();

    verify(() => mockPurchaseService.restorePurchases()).called(1);
    verify(() => mockAuthService.refreshToken()).called(1);
    expect(find.textContaining('Welcome to Premium'), findsOneWidget);
  });

  testWidgets('restore shows error snackbar on failure', (tester) async {
    when(() => mockPurchaseService.restorePurchases())
        .thenThrow(Exception('restore failed'));

    await tester.pumpWidget(_wrap(
      purchaseService: mockPurchaseService,
      authService: mockAuthService,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore purchase'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Purchase failed'), findsOneWidget);
  });
}
