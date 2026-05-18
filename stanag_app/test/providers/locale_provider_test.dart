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
    SharedPreferences.setMockInitialValues({});
  });

  // ── build() / initial state ────────────────────────────────────────────────

  group('build()', () {
    test('is in AsyncLoading before the async build completes', () {
      final container = _makeContainer();

      expect(container.read(localeProvider), isA<AsyncLoading<Locale>>());
    });

    test('resolves to Locale(en) when no saved preference exists', () async {
      final container = _makeContainer();

      expect(await container.read(localeProvider.future), const Locale('en'));
    });

    test('restores saved Locale(pl) from SharedPreferences on startup', () async {
      SharedPreferences.setMockInitialValues({'interface_lang': 'pl'});
      final container = _makeContainer();

      expect(await container.read(localeProvider.future), const Locale('pl'));
    });

    test('restores saved Locale(en) when en is explicitly stored', () async {
      SharedPreferences.setMockInitialValues({'interface_lang': 'en'});
      final container = _makeContainer();

      expect(await container.read(localeProvider.future), const Locale('en'));
    });
  });

  // ── setLocale() ────────────────────────────────────────────────────────────

  group('setLocale()', () {
    test('updates state synchronously before the SharedPreferences write', () async {
      final container = _makeContainer();
      await container.read(localeProvider.future); // wait for build

      // setLocale sets state = AsyncData before its first await.
      container.read(localeProvider.notifier).setLocale(const Locale('pl'));

      expect(container.read(localeProvider).asData?.value, const Locale('pl'));
    });

    test('persists the chosen locale to SharedPreferences', () async {
      final container = _makeContainer();
      await container.read(localeProvider.future);

      await container.read(localeProvider.notifier).setLocale(const Locale('pl'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('interface_lang'), 'pl');
    });

    test('switching back to Locale(en) overwrites the stored value', () async {
      final container = _makeContainer();
      await container.read(localeProvider.future);
      await container.read(localeProvider.notifier).setLocale(const Locale('pl'));
      await container.read(localeProvider.notifier).setLocale(const Locale('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('interface_lang'), 'en');
      expect(container.read(localeProvider).asData?.value, const Locale('en'));
    });

    test('unsupported locale is persisted as-is without validation', () async {
      // LocaleNotifier does not restrict input — intentional so the app can
      // be extended to more locales without touching the notifier.
      final container = _makeContainer();
      await container.read(localeProvider.future);
      await container.read(localeProvider.notifier).setLocale(const Locale('fr'));

      expect(container.read(localeProvider).asData?.value, const Locale('fr'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('interface_lang'), 'fr');
    });

    test('round-trip: persisted value is loaded by a fresh provider', () async {
      final first = _makeContainer();
      await first.read(localeProvider.future);
      await first.read(localeProvider.notifier).setLocale(const Locale('pl'));

      // New container — replicates a fresh app launch reading from the store.
      final second = _makeContainer();
      expect(await second.read(localeProvider.future), const Locale('pl'));
    });
  });
}
