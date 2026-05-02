import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanag_app/main.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/providers/purchase_provider.dart';
import 'package:stanag_app/screens/forgot_password_screen.dart';
import 'package:stanag_app/screens/home_screen.dart';
import 'package:stanag_app/screens/login_screen.dart';
import 'package:stanag_app/screens/progress_screen.dart';
import 'package:stanag_app/screens/register_screen.dart';
import 'package:stanag_app/screens/settings_screen.dart';
import 'package:stanag_app/screens/upgrade_screen.dart';
import 'package:stanag_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

/// Pumps [MyApp] with a fixed user state.
Widget _buildApp(UserState state) => ProviderScope(
      overrides: [
        userStateProvider.overrideWith((ref) => Stream.value(state)),
      ],
      child: const MyApp(),
    );

/// Returns the GoRouter instance from the current widget tree.
/// Requires [HomeScreen] to be visible (call before navigating away from it).
GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(HomeScreen)));

void main() {
  setUp(() {
    // Required for SettingsScreen (notificationPreferencesProvider) and
    // locale restoration — both read SharedPreferences on first render.
    SharedPreferences.setMockInitialValues({});
  });

  // ── redirect — registered user blocked from auth routes ───────────────────
  //
  // Line 35: if (isRegistered && _authRoutes.contains(location)) return '/home';

  group('redirect — registered user blocked from auth routes', () {
    for (final state in const [
      UserState.registeredFree,
      UserState.registeredPremium,
      UserState.expiredPremium,
    ]) {
      testWidgets('$state at /login is redirected to /home', (tester) async {
        await tester.pumpWidget(_buildApp(state));
        await tester.pumpAndSettle();

        _router(tester).go('/login');
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      });
    }

    testWidgets('registeredFree at /register is redirected to /home',
        (tester) async {
      await tester.pumpWidget(_buildApp(UserState.registeredFree));
      await tester.pumpAndSettle();

      _router(tester).go('/register');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    });

    testWidgets('registeredFree at /forgot-password is redirected to /home',
        (tester) async {
      await tester.pumpWidget(_buildApp(UserState.registeredFree));
      await tester.pumpAndSettle();

      _router(tester).go('/forgot-password');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });
  });

  // ── redirect — anonymous user can reach auth routes ───────────────────────
  //
  // Line 37: return null (no redirect for anonymous user at auth routes).
  // Also exercises the route builders for /register, /login, /forgot-password
  // (lines 74, 78, 82).

  group('redirect — anonymous user can reach auth routes', () {
    testWidgets('anonymous at /register lands on RegisterScreen',
        (tester) async {
      await tester.pumpWidget(_buildApp(UserState.anonymous));
      await tester.pumpAndSettle();

      _router(tester).go('/register');
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('anonymous at /login lands on LoginScreen', (tester) async {
      await tester.pumpWidget(_buildApp(UserState.anonymous));
      await tester.pumpAndSettle();

      _router(tester).go('/login');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('anonymous at /forgot-password lands on ForgotPasswordScreen',
        (tester) async {
      await tester.pumpWidget(_buildApp(UserState.anonymous));
      await tester.pumpAndSettle();

      _router(tester).go('/forgot-password');
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });

  // ── route builders ────────────────────────────────────────────────────────
  //
  // Exercises the builder lambdas for routes not yet reached in any other test:
  // /progress (line 64), /settings (line 68), /upgrade (line 86).

  group('route builders', () {
    testWidgets('navigate to /progress shows ProgressScreen', (tester) async {
      await tester.pumpWidget(_buildApp(UserState.registeredFree));
      await tester.pumpAndSettle();

      _router(tester).go('/progress');
      await tester.pumpAndSettle();

      expect(find.byType(ProgressScreen), findsOneWidget);
    });

    testWidgets('navigate to /settings shows SettingsScreen', (tester) async {
      // SettingsScreen reads authServiceProvider.currentUser in build().
      final mockAuthService = MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          userStateProvider.overrideWith((ref) => Stream.value(UserState.registeredFree)),
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
        child: const MyApp(),
      ));
      await tester.pumpAndSettle();

      _router(tester).go('/settings');
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('navigate to /upgrade shows UpgradeScreen', (tester) async {
      // UpgradeScreen shows CircularProgressIndicator while offeringsProvider
      // is loading — pumpAndSettle() would time out. Force the error state
      // (plain text, no animation) by overriding the provider to throw.
      await tester.pumpWidget(ProviderScope(
        overrides: [
          userStateProvider.overrideWith((ref) => Stream.value(UserState.registeredFree)),
          offeringsProvider.overrideWith(
            (ref) async => throw Exception('offerings unavailable'),
          ),
        ],
        child: const MyApp(),
      ));
      await tester.pumpAndSettle();

      _router(tester).go('/upgrade');
      await tester.pumpAndSettle();

      expect(find.byType(UpgradeScreen), findsOneWidget);
    });
  });
}
