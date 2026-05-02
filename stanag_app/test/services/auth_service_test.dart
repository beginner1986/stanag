import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stanag_app/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService sut;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

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

  // ── registerWithEmail ──────────────────────────────────────────────────────

  group('registerWithEmail', () {
    test('calls linkWithCredential on the current user', () async {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.linkWithCredential(any()))
          .thenAnswer((_) async => MockUserCredential());

      await sut.registerWithEmail('a@b.com', 'password123');

      verify(() => user.linkWithCredential(any())).called(1);
    });

    test('rethrows FirebaseAuthException when email is already in use', () async {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.linkWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'email-already-in-use'),
      );

      expect(
        () => sut.registerWithEmail('a@b.com', 'password123'),
        throwsA(isA<FirebaseAuthException>().having((e) => e.code, 'code', 'email-already-in-use')),
      );
    });
  });

  // ── signInWithEmail ────────────────────────────────────────────────────────

  group('signInWithEmail', () {
    test('calls signInWithEmailAndPassword with correct credentials', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'a@b.com',
            password: 'password123',
          )).thenAnswer((_) async => MockUserCredential());

      await sut.signInWithEmail('a@b.com', 'password123');

      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'a@b.com',
            password: 'password123',
          )).called(1);
    });

    test('rethrows FirebaseAuthException on wrong password', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => sut.signInWithEmail('a@b.com', 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ── sendPasswordResetEmail ─────────────────────────────────────────────────

  group('sendPasswordResetEmail', () {
    test('calls FirebaseAuth.sendPasswordResetEmail with the given email', () async {
      when(() => mockAuth.sendPasswordResetEmail(email: 'a@b.com'))
          .thenAnswer((_) async {});

      await sut.sendPasswordResetEmail('a@b.com');

      verify(() => mockAuth.sendPasswordResetEmail(email: 'a@b.com')).called(1);
    });

    test('rethrows FirebaseAuthException when user is not found', () async {
      when(() => mockAuth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      expect(
        () => sut.sendPasswordResetEmail('noone@b.com'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ── signOut ────────────────────────────────────────────────────────────────

  group('signOut', () {
    test('calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await sut.signOut();

      verify(() => mockAuth.signOut()).called(1);
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
