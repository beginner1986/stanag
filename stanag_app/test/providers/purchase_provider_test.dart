import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stanag_app/providers/purchase_provider.dart';
import 'package:stanag_app/services/purchase_service.dart';

class MockPurchaseService extends Mock implements PurchaseService {}

// ── Fake offerings ────────────────────────────────────────────────────────────

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

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(PurchaseService service) {
  final container = ProviderContainer(
    overrides: [purchaseServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Awaits the first settled emission from [offeringsProvider].
///
/// In Riverpod 3.x, FutureProvider error states are emitted as
/// `AsyncLoading` with `hasError == true` (isLoading stays true). Success
/// states arrive as `AsyncData` with `isLoading == false`. So we settle on
/// whichever condition fires first.
Future<AsyncValue<Offerings>> _awaitSettled(ProviderContainer container) {
  final completer = Completer<AsyncValue<Offerings>>();
  container.listen<AsyncValue<Offerings>>(
    offeringsProvider,
    (_, next) {
      if ((next.hasError || !next.isLoading) && !completer.isCompleted) {
        completer.complete(next);
      }
    },
    fireImmediately: true,
  );
  return completer.future;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── purchaseServiceProvider ──────────────────────────────────────────────

  group('purchaseServiceProvider', () {
    test('returns a RevenueCatPurchaseService by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Just instantiating the class — no SDK calls are made here.
      expect(
        container.read(purchaseServiceProvider),
        isA<RevenueCatPurchaseService>(),
      );
    });
  });

  // ── offeringsProvider ────────────────────────────────────────────────────

  group('offeringsProvider', () {
    late MockPurchaseService mockService;

    setUp(() => mockService = MockPurchaseService());

    // ── loading ─────────────────────────────────────────────────────────────

    test('is in AsyncLoading before getOfferings() completes', () async {
      final pending = Completer<Offerings>();
      when(() => mockService.getOfferings()).thenAnswer((_) => pending.future);
      final container = _makeContainer(mockService);

      // Read before any microtask runs — provider must be in loading state.
      final initial = container.read(offeringsProvider);
      expect(initial, isA<AsyncLoading<Offerings>>());

      // Unblock so the container settles cleanly before tearDown disposes it.
      pending.complete(_fakeOfferings);
      await _awaitSettled(container);
    });

    // ── success ──────────────────────────────────────────────────────────────

    test('emits AsyncData containing the fetched Offerings', () async {
      when(() => mockService.getOfferings())
          .thenAnswer((_) async => _fakeOfferings);
      final container = _makeContainer(mockService);

      final result = await _awaitSettled(container);

      expect(result, isA<AsyncData<Offerings>>());
      expect(result.requireValue, same(_fakeOfferings));
    });

    test('calls getOfferings() exactly once per provider instantiation',
        () async {
      when(() => mockService.getOfferings())
          .thenAnswer((_) async => _fakeOfferings);
      final container = _makeContainer(mockService);

      await _awaitSettled(container);

      verify(() => mockService.getOfferings()).called(1);
    });

    // ── error paths ──────────────────────────────────────────────────────────

    test('emits AsyncError when getOfferings() throws PurchasesError', () async {
      // thenAnswer with an async lambda is required: thenThrow emits a
      // synchronous throw before returning a Future, which Riverpod 3.x does
      // not convert to AsyncError. An async lambda returns a rejected Future
      // that Riverpod can properly await and catch.
      when(() => mockService.getOfferings()).thenAnswer(
        (_) async => throw PurchasesError(
          PurchasesErrorCode.networkError,
          'network error',
          'no internet',
          'NETWORK_ERROR',
        ),
      );
      final container = _makeContainer(mockService);

      final result = await _awaitSettled(container);

      // In Riverpod 3.x the error state is AsyncLoading with hasError=true.
      expect(result.hasError, isTrue);
      expect(result.error, isA<PurchasesError>());
      expect(
        (result.error! as PurchasesError).code,
        PurchasesErrorCode.networkError,
      );
    });

    test('propagates error state when getOfferings() throws a generic exception',
        () async {
      when(() => mockService.getOfferings())
          .thenAnswer((_) async => throw Exception('unexpected SDK failure'));
      final container = _makeContainer(mockService);

      final result = await _awaitSettled(container);

      expect(result.hasError, isTrue);
      expect(result.error, isA<Exception>());
    });

    // ── wiring ───────────────────────────────────────────────────────────────

    test('reads from purchaseServiceProvider, not a hard-coded service',
        () async {
      // A second mock whose getOfferings() is never called — if the provider
      // bypassed purchaseServiceProvider it would call the wrong instance.
      final otherMock = MockPurchaseService();
      when(() => mockService.getOfferings())
          .thenAnswer((_) async => _fakeOfferings);
      final container = _makeContainer(mockService);

      await _awaitSettled(container);

      verify(() => mockService.getOfferings()).called(1);
      verifyNever(() => otherMock.getOfferings());
    });
  });
}
