import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/login_screen.dart';
import 'package:stanag_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

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
        home: child,
      ),
    );

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  // ── initial render ─────────────────────────────────────────────────────────

  group('initial render', () {
    testWidgets('shows email and password fields and the sign-in button', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
    });

    testWidgets('shows no error message on first render', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsNothing);
      expect(find.text('Something went wrong. Please try again.'), findsNothing);
    });
  });

  // ── form validation ────────────────────────────────────────────────────────

  group('form validation', () {
    testWidgets('shows email error when email field is empty', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      verifyNever(() => mockAuthService.signInWithEmail(any(), any()));
    });

    testWidgets('shows password error when password is too short', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
      verifyNever(() => mockAuthService.signInWithEmail(any(), any()));
    });
  });

  // ── successful sign-in ─────────────────────────────────────────────────────

  group('successful sign-in', () {
    testWidgets('calls signInWithEmail with trimmed email and password', (tester) async {
      when(() => mockAuthService.signInWithEmail(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(const LoginScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '  test@example.com  ');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signInWithEmail('test@example.com', 'password123')).called(1);
    });
  });

  // ── credential errors ──────────────────────────────────────────────────────

  group('credential errors', () {
    for (final code in ['wrong-password', 'user-not-found', 'invalid-credential']) {
      testWidgets('shows invalid-credentials message for $code', (tester) async {
        when(() => mockAuthService.signInWithEmail(any(), any()))
            .thenThrow(FirebaseAuthException(code: code));

        await tester.pumpWidget(_wrap(const LoginScreen(), authService: mockAuthService));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('Incorrect email or password.'), findsOneWidget);
      });
    }

    testWidgets('shows generic error for other FirebaseAuthExceptions', (tester) async {
      when(() => mockAuthService.signInWithEmail(any(), any()))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await tester.pumpWidget(_wrap(const LoginScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    });
  });
}
