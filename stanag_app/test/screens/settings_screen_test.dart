import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/settings_screen.dart';
import 'package:stanag_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

Widget _wrap({
  required AuthService authService,
  UserState userState = UserState.anonymous,
  String? email,
}) {
  if (email != null) {
    final mockUser = MockUser();
    when(() => mockUser.email).thenReturn(email);
    when(() => authService.currentUser).thenReturn(mockUser);
  } else {
    when(() => authService.currentUser).thenReturn(null);
  }

  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
      userStateProvider.overrideWith(
        (ref) => Stream.value(userState),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: SettingsScreen(),
    ),
  );
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthService = MockAuthService();
  });

  // ── initial render ─────────────────────────────────────────────────────────

  group('initial render', () {
    testWidgets('shows language section and account section', (tester) async {
      await tester.pumpWidget(_wrap(authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('shows Privacy Policy and Terms of Service links', (tester) async {
      await tester.pumpWidget(_wrap(authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });
  });

  // ── account section ────────────────────────────────────────────────────────

  group('account section', () {
    testWidgets('shows Guest for anonymous user', (tester) async {
      await tester.pumpWidget(_wrap(
        authService: mockAuthService,
        userState: UserState.anonymous,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('shows email and sign-out for registered user', (tester) async {
      await tester.pumpWidget(_wrap(
        authService: mockAuthService,
        userState: UserState.registeredFree,
        email: 'test@example.com',
      ));
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('sign-out calls signOut then signInAnonymously', (tester) async {
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});
      when(() => mockAuthService.signInAnonymously()).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(
        authService: mockAuthService,
        userState: UserState.registeredFree,
        email: 'test@example.com',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signOut()).called(1);
      verify(() => mockAuthService.signInAnonymously()).called(1);
    });
  });

  // ── language toggle ────────────────────────────────────────────────────────

  group('language toggle', () {
    testWidgets('shows English and Polski segments', (tester) async {
      await tester.pumpWidget(_wrap(authService: mockAuthService));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Polski'), findsOneWidget);
    });
  });
}
