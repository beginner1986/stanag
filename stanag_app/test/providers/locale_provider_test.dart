import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanag_app/providers/locale_provider.dart';

ProviderContainer _makeContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() {
    // Reset the SharedPreferences mock store before each test.
    SharedPreferences.setMockInitialValues({});
  });

  // ── build() / initial state ────────────────────────────────────────────────

  group('build()', () {
    test('returns Locale(en) synchronously before the async load completes', () {
      final container = _makeContainer();

      // Read without waiting — should see the synchronous default.
      expect(container.read(localeProvider), const Locale('en'));
    });

    test('keeps Locale(en) when no saved preference exists', () async {
      final container = _makeContainer();
      container.read(localeProvider); // trigger _loadSavedLocale()
      await Future.delayed(Duration.zero); // flush async work

      expect(container.read(localeProvider), const Locale('en'));
    });

    test('restores saved Locale(pl) from SharedPreferences on startup', () async {
      SharedPreferences.setMockInitialValues({'interface_lang': 'pl'});
      final container = _makeContainer();
      container.read(localeProvider); // trigger _loadSavedLocale()
      await Future.delayed(Duration.zero); // flush async work

      expect(container.read(localeProvider), const Locale('pl'));
    });

    test('restores saved Locale(en) without redundant state change', () async {
      // Saving 'en' should result in the same Locale('en') state — no crash.
      SharedPreferences.setMockInitialValues({'interface_lang': 'en'});
      final container = _makeContainer();
      container.read(localeProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(localeProvider), const Locale('en'));
    });
  });

  // ── setLocale() ────────────────────────────────────────────────────────────

  group('setLocale()', () {
    test('updates state synchronously before the SharedPreferences write', () {
      final container = _makeContainer();
      container.read(localeProvider); // initialise

      // setLocale is async, but state = newLocale runs before the first await.
      container.read(localeProvider.notifier).setLocale(const Locale('pl'));

      expect(container.read(localeProvider), const Locale('pl'));
    });

    test('persists the chosen locale to SharedPreferences', () async {
      final container = _makeContainer();
      container.read(localeProvider);

      await container.read(localeProvider.notifier).setLocale(const Locale('pl'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('interface_lang'), 'pl');
    });

    test('switching back to Locale(en) overwrites the stored value', () async {
      final container = _makeContainer();
      container.read(localeProvider);
      await container.read(localeProvider.notifier).setLocale(const Locale('pl'));
      await container.read(localeProvider.notifier).setLocale(const Locale('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('interface_lang'), 'en');
      expect(container.read(localeProvider), const Locale('en'));
    });

    test('unsupported locale is persisted as-is without validation', () async {
      // LocaleNotifier does not restrict input — this is intentional so the
      // app can be extended to more locales without touching the notifier.
      final container = _makeContainer();
      container.read(localeProvider);
      await container.read(localeProvider.notifier).setLocale(const Locale('fr'));

      expect(container.read(localeProvider), const Locale('fr'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('interface_lang'), 'fr');
    });

    test('round-trip: persisted value is loaded by a fresh provider', () async {
      // Simulates the user picking Polish, closing the app, and relaunching.
      final first = _makeContainer();
      first.read(localeProvider);
      await first.read(localeProvider.notifier).setLocale(const Locale('pl'));

      // New container — replicates a fresh app launch reading from the store.
      final second = _makeContainer();
      second.read(localeProvider);
      await Future.delayed(Duration.zero); // flush _loadSavedLocale()

      expect(second.read(localeProvider), const Locale('pl'));
    });
  });
}
