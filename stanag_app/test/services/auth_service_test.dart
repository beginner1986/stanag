import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stanag_app/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService sut;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    sut = AuthService(mockAuth);
  });

  // ── currentUser ────────────────────────────────────────────────────────────

  group('currentUser', () {
    test('returns null when no user is signed in', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(sut.currentUser, isNull);
    });

    test('returns the signed-in user', () {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);

      expect(sut.currentUser, same(user));
    });
  });

  // ── signInAnonymously ──────────────────────────────────────────────────────

  group('signInAnonymously', () {
    test('calls FirebaseAuth.signInAnonymously when no user is signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.signInAnonymously())
          .thenAnswer((_) async => MockUserCredential());

      await sut.signInAnonymously();

      verify(() => mockAuth.signInAnonymously()).called(1);
    });

    test('skips the Firebase call when a user is already signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(MockUser());

      await sut.signInAnonymously();

      verifyNever(() => mockAuth.signInAnonymously());
    });

    test('rethrows FirebaseAuthException from the underlying call', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.signInAnonymously()).thenThrow(
        FirebaseAuthException(code: 'network-request-failed'),
      );

      expect(
        () => sut.signInAnonymously(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ── refreshToken ───────────────────────────────────────────────────────────

  group('refreshToken', () {
    test('calls getIdToken(true) on the current user', () async {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'new-token');

      await sut.refreshToken();

      verify(() => user.getIdToken(true)).called(1);
    });

    test('does nothing when there is no current user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      // Should complete without throwing.
      await expectLater(sut.refreshToken(), completes);
    });

    test('rethrows when getIdToken throws', () async {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true))
          .thenThrow(FirebaseAuthException(code: 'user-token-expired'));

      expect(
        () => sut.refreshToken(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
