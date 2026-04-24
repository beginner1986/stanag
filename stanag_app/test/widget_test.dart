import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanag_app/main.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/home_screen.dart';
import 'package:stanag_app/screens/splash_screen.dart';

void main() {
  // ── MyApp widget ───────────────────────────────────────────────────────────

  group('MyApp', () {
    testWidgets('shows LanguageTestScreen when userState has data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStateProvider.overrideWith(
              (ref) => Stream.value(UserState.anonymous),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('shows SplashScreen while userState is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // A stream that never emits keeps the provider in AsyncLoading.
            userStateProvider.overrideWith(
              (ref) => Stream<UserState>.multi((_) {}),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LanguageTestScreen), findsNothing);
    });

    testWidgets('shows SplashScreen when userState has an error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStateProvider.overrideWith(
              (ref) => Stream<UserState>.fromFuture(
                Future.error(Exception('auth error')),
              ),
            ),
          ],
          child: const MyApp(),
        ),
      );
      // pump() once to flush microtasks (stream error delivery + Riverpod state),
      // then again to process the resulting widget rebuild.
      // pumpAndSettle() cannot be used: CircularProgressIndicator animates forever.
      await tester.pump();
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LanguageTestScreen), findsNothing);
    });
  });

  // ── FLAVOR constant ────────────────────────────────────────────────────────

  group('FLAVOR constant', () {
    test('defaults to dev in the test environment', () {
      // Guards against a mis-configured CI job accidentally running tests
      // against staging/prod Firebase options.
      expect(flavor, 'dev');
    });
  });
}
