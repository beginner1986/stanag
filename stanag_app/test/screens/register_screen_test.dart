import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/register_screen.dart';
import 'package:stanag_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class FakeAuthCredential extends Fake implements AuthCredential {}

Widget _wrap(Widget child, {AuthService? authService}) => ProviderScope(
      overrides: [
        if (authService != null)
          authServiceProvider.overrideWithValue(authService),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        // Use onGenerateRoute to handle GoRouter's context.go('/login') without
        // a real GoRouter in tests. Unknown routes fall back to a stub screen.
        home: child,
      ),
    );

void main() {
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockAuthService = MockAuthService();
  });

  // ── initial render ─────────────────────────────────────────────────────────

  group('initial render', () {
    testWidgets('shows email and password fields and the register button', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });

    testWidgets('shows no error message on first render', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again.'), findsNothing);
    });
  });

  // ── form validation ────────────────────────────────────────────────────────

  group('form validation', () {
    testWidgets('shows email error when email field is empty', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      verifyNever(() => mockAuthService.registerWithEmail(any(), any()));
    });

    testWidgets('shows email error when email has no @ symbol', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('shows password error when password is too short', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '12345');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('does not call registerWithEmail when validation fails', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      verifyNever(() => mockAuthService.registerWithEmail(any(), any()));
    });
  });

  // ── successful registration ────────────────────────────────────────────────

  group('successful registration', () {
    testWidgets('calls registerWithEmail with trimmed email and password', (tester) async {
      when(() => mockAuthService.registerWithEmail(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '  test@example.com  ');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.registerWithEmail('test@example.com', 'password123')).called(1);
    });
  });

  // ── email-already-in-use ───────────────────────────────────────────────────

  group('email already in use', () {
    testWidgets('shows dialog when email-already-in-use is thrown', (tester) async {
      when(() => mockAuthService.registerWithEmail(any(), any()))
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'taken@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Email already registered'), findsOneWidget);
      expect(find.text('An account with this email already exists. Sign in instead?'), findsOneWidget);
    });

    testWidgets('shows dialog when credential-already-in-use is thrown', (tester) async {
      when(() => mockAuthService.registerWithEmail(any(), any()))
          .thenThrow(FirebaseAuthException(code: 'credential-already-in-use'));

      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'taken@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Email already registered'), findsOneWidget);
    });

    testWidgets('dismisses dialog on Cancel tap', (tester) async {
      when(() => mockAuthService.registerWithEmail(any(), any()))
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'taken@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  // ── generic error ──────────────────────────────────────────────────────────

  group('generic error', () {
    testWidgets('shows generic error message for other FirebaseAuthExceptions', (tester) async {
      when(() => mockAuthService.registerWithEmail(any(), any()))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await tester.pumpWidget(_wrap(const RegisterScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
