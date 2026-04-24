import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/forgot_password_screen.dart';
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
    testWidgets('shows description, email field and send button', (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.text("Enter your email and we'll send you a reset link."), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send reset email'), findsOneWidget);
    });

    testWidgets('shows no error and no success message on first render', (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.text('Reset link sent. Check your inbox.'), findsNothing);
      expect(find.text('Something went wrong. Please try again.'), findsNothing);
    });
  });

  // ── form validation ────────────────────────────────────────────────────────

  group('form validation', () {
    testWidgets('shows email error when field is empty', (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      verifyNever(() => mockAuthService.sendPasswordResetEmail(any()));
    });

    testWidgets('shows email error when email has no @ symbol', (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });
  });

  // ── successful send ────────────────────────────────────────────────────────

  group('successful send', () {
    testWidgets('shows success message and hides the form after sending', (tester) async {
      when(() => mockAuthService.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
      await tester.pumpAndSettle();

      expect(find.text('Reset link sent. Check your inbox.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('calls sendPasswordResetEmail with trimmed email', (tester) async {
      when(() => mockAuthService.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '  test@example.com  ');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.sendPasswordResetEmail('test@example.com')).called(1);
    });
  });

  // ── errors ─────────────────────────────────────────────────────────────────

  group('errors', () {
    testWidgets('shows user-not-found message when that exception is thrown', (tester) async {
      when(() => mockAuthService.sendPasswordResetEmail(any()))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'nobody@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
      await tester.pumpAndSettle();

      expect(find.text('No account found with this email.'), findsOneWidget);
      expect(find.text('Reset link sent. Check your inbox.'), findsNothing);
    });

    testWidgets('shows generic error for other FirebaseAuthExceptions', (tester) async {
      when(() => mockAuthService.sendPasswordResetEmail(any()))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(find.text('Reset link sent. Check your inbox.'), findsNothing);
    });

    testWidgets('keeps form visible after an error so user can retry', (tester) async {
      when(() => mockAuthService.sendPasswordResetEmail(any()))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), authService: mockAuthService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send reset email'), findsOneWidget);
    });
  });
}
