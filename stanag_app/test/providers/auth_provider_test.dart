import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/providers/firebase_providers.dart';
import 'package:stanag_app/repositories/interfaces/user_repository.dart';
import 'package:stanag_app/services/auth_service.dart';
import '../mocks/firebase_mocks.dart';

class MockIdTokenResult extends Mock implements IdTokenResult {}

// ── helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(FirebaseAuth auth) => ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );

/// Returns a non-anonymous [MockUser] whose token resolves to [claims].
MockUser _userWithClaims(Map<String, dynamic> claims) {
  final tokenResult = MockIdTokenResult();
  when(() => tokenResult.claims).thenReturn(claims);

  final user = MockUser();
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.getIdTokenResult()).thenAnswer((_) async => tokenResult);
  return user;
}

/// Waits for the first [AsyncData] emission from [userStateProvider].
Future<UserState> _awaitFirst(ProviderContainer container) {
  final completer = Completer<UserState>();
  container.listen<AsyncValue<UserState>>(
    userStateProvider,
    (_, next) {
      if (next.hasValue && !completer.isCompleted) {
        completer.complete(next.requireValue);
      }
    },
    fireImmediately: true,
  );
  return completer.future;
}

/// Collects the first [count] [AsyncData] emissions from [userStateProvider].
Future<List<UserState>> _awaitN(ProviderContainer container, int count) {
  final states = <UserState>[];
  final completer = Completer<List<UserState>>();
  container.listen<AsyncValue<UserState>>(
    userStateProvider,
    (_, next) {
      if (next.hasValue) {
        states.add(next.requireValue);
        if (states.length >= count && !completer.isCompleted) {
          completer.complete(List.unmodifiable(states));
        }
      }
    },
    fireImmediately: true,
  );
  return completer.future;
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── authServiceProvider ───────────────────────────────────────────────────

  group('authServiceProvider', () {
    test('returns an AuthService wrapping the injected FirebaseAuth', () {
      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(MockFirebaseAuth())],
      );
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), isA<AuthService>());
    });
  });

  // ── userRepositoryProvider ────────────────────────────────────────────────

  group('userRepositoryProvider', () {
    test('returns a UserRepository backed by the injected Firestore', () {
      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(FakeFirebaseFirestore())],
      );
      addTearDown(container.dispose);

      expect(container.read(userRepositoryProvider), isA<UserRepository>());
    });
  });

  group('userStateProvider', () {
    late MockFirebaseAuth mockAuth;
    late ProviderContainer container;

    setUp(() => mockAuth = MockFirebaseAuth());
    tearDown(() => container.dispose());

    // ── anonymous ───────────────────────────────────────────────────────────

    test('yields anonymous when the stream emits null', () async {
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(null));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.anonymous);
    });

    test('yields anonymous for an anonymous (guest) Firebase user', () async {
      final user = MockUser();
      when(() => user.isAnonymous).thenReturn(true);
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.anonymous);
    });

    // ── registeredFree ──────────────────────────────────────────────────────

    test('yields registeredFree when is_premium is false', () async {
      final user = _userWithClaims({'is_premium': false});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.registeredFree);
    });

    test('yields registeredFree when is_premium claim is absent', () async {
      final user = _userWithClaims({});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.registeredFree);
    });

    test('yields anonymous when getIdTokenResult throws', () async {
      final user = MockUser();
      when(() => user.isAnonymous).thenReturn(false);
      when(() => user.getIdTokenResult()).thenThrow(Exception('network'));
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.anonymous);
    });

    // ── registeredPremium ───────────────────────────────────────────────────

    test('yields registeredPremium when is_premium is true and no expiry claim', () async {
      final user = _userWithClaims({'is_premium': true});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.registeredPremium);
    });

    test('yields registeredPremium when premium_until is a future int (Unix seconds)', () async {
      final ts = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
      final user = _userWithClaims({'is_premium': true, 'premium_until': ts});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.registeredPremium);
    });

    test('yields registeredPremium when premium_until is a future double (Unix seconds)', () async {
      final ts = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch / 1000.0;
      final user = _userWithClaims({'is_premium': true, 'premium_until': ts});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.registeredPremium);
    });

    test('yields registeredPremium when premium_until is a future ISO-8601 string', () async {
      final ts = DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String();
      final user = _userWithClaims({'is_premium': true, 'premium_until': ts});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.registeredPremium);
    });

    test('yields registeredPremium when premium_until is an unrecognised type (no expiry applied)', () async {
      // Unknown type → _parsePremiumUntil returns null → no expiry date → still active
      final user = _userWithClaims({'is_premium': true, 'premium_until': ['not', 'a', 'date']});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.registeredPremium);
    });

    // ── expiredPremium ──────────────────────────────────────────────────────

    test('yields expiredPremium when premium_until (int) is in the past', () async {
      final ts = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
      final user = _userWithClaims({'is_premium': true, 'premium_until': ts});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.expiredPremium);
    });

    test('yields expiredPremium when premium_until (double) is in the past', () async {
      final ts = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch / 1000.0;
      final user = _userWithClaims({'is_premium': true, 'premium_until': ts});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.expiredPremium);
    });

    test('yields expiredPremium when premium_until ISO-8601 string is in the past', () async {
      final ts = DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String();
      final user = _userWithClaims({'is_premium': true, 'premium_until': ts});
      when(() => mockAuth.idTokenChanges())
          .thenAnswer((_) => Stream.value(user));
      container = _makeContainer(mockAuth);

      expect(await _awaitFirst(container), UserState.expiredPremium);
    });

    // ── state transitions ───────────────────────────────────────────────────

    test('emits correct sequence across multiple token changes: anonymous → free → premium', () async {
      final anonUser = MockUser();
      when(() => anonUser.isAnonymous).thenReturn(true);

      final freeUser = _userWithClaims({'is_premium': false});

      final futureTs = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
      final premiumUser = _userWithClaims({'is_premium': true, 'premium_until': futureTs});

      when(() => mockAuth.idTokenChanges()).thenAnswer(
        (_) => Stream.fromIterable([anonUser, freeUser, premiumUser]),
      );
      container = _makeContainer(mockAuth);

      expect(
        await _awaitN(container, 3),
        [UserState.anonymous, UserState.registeredFree, UserState.registeredPremium],
      );
    });
  });
}
