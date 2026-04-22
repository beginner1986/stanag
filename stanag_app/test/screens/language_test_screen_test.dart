import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanag_app/main.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';

// Renders the full app with the data state forced so LanguageTestScreen is shown.
// localeProvider is left unoverridden so real switching behaviour is exercised.
Widget _appWithDataState() => ProviderScope(
      overrides: [
        userStateProvider.overrideWith(
          (ref) => Stream.value(UserState.anonymous),
        ),
      ],
      child: const MyApp(),
    );

void main() {
  setUp(() {
    // Reset the SharedPreferences mock store so locale tests don't bleed between runs.
    SharedPreferences.setMockInitialValues({});
  });

  // ── initial render ─────────────────────────────────────────────────────────

  group('initial render (English locale)', () {
    testWidgets('shows app name in the AppBar', (tester) async {
      await tester.pumpWidget(_appWithDataState());
      await tester.pumpAndSettle();

      expect(find.text('STANAG English'), findsOneWidget);
    });

    testWidgets('shows both language buttons', (tester) async {
      await tester.pumpWidget(_appWithDataState());
      await tester.pumpAndSettle();

      expect(find.text('Polski'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
    });

    testWidgets(
        'languageName body text reads "English" and Polski appears only as a button',
        (tester) async {
      await tester.pumpWidget(_appWithDataState());
      await tester.pumpAndSettle();

      // "English" appears twice: as the localized languageName body text AND
      // as the English button label.
      expect(find.text('English'), findsNWidgets(2));
      // "Polski" appears once: only the Polski button label.
      expect(find.text('Polski'), findsOneWidget);
    });
  });

  // ── locale switching ───────────────────────────────────────────────────────

  group('locale switching', () {
    testWidgets('tapping Polski switches languageName to "Polski"', (tester) async {
      await tester.pumpWidget(_appWithDataState());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Polski'));
      await tester.pumpAndSettle();

      // "Polski" now appears as both the localized languageName body text AND
      // the button label; "English" is reduced to just the button.
      expect(find.text('Polski'), findsNWidgets(2));
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('tapping English after Polski switches languageName back to "English"',
        (tester) async {
      await tester.pumpWidget(_appWithDataState());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Polski'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'English'));
      await tester.pumpAndSettle();

      // Back to English locale.
      expect(find.text('English'), findsNWidgets(2));
      expect(find.text('Polski'), findsOneWidget);
    });

    testWidgets('tapping the already-active locale button is harmless', (tester) async {
      // Tapping English when already in English should not crash or produce a
      // duplicate state change.
      await tester.pumpWidget(_appWithDataState());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'English'));
      await tester.pumpAndSettle();

      // State is unchanged.
      expect(find.text('English'), findsNWidgets(2));
      expect(find.text('Polski'), findsOneWidget);
    });

    testWidgets('tapping Polski twice leaves locale in Polish', (tester) async {
      await tester.pumpWidget(_appWithDataState());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Polski'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Polski'));
      await tester.pumpAndSettle();

      expect(find.text('Polski'), findsNWidgets(2));
      expect(find.text('English'), findsOneWidget);
    });
  });
}
