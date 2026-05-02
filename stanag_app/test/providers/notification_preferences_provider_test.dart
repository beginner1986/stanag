import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanag_app/providers/notification_preferences_provider.dart';

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
    test('returns disabled with 08:00 synchronously before async load', () {
      final container = _makeContainer();

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.enabled, false);
      expect(prefs.reminderTime, const TimeOfDay(hour: 8, minute: 0));
    });

    test('keeps defaults when SharedPreferences is empty', () async {
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);
      await Future.delayed(Duration.zero);

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.enabled, false);
      expect(prefs.reminderTime, const TimeOfDay(hour: 8, minute: 0));
    });

    test('restores enabled=true from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(notificationPreferencesProvider).enabled, true);
    });

    test('restores saved reminder time from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'notifications_hour': 9,
        'notifications_minute': 30,
      });
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);
      await Future.delayed(Duration.zero);

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.reminderTime, const TimeOfDay(hour: 9, minute: 30));
    });
  });

  // ── setEnabled() ───────────────────────────────────────────────────────────

  group('setEnabled()', () {
    test('updates state synchronously', () {
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);

      container.read(notificationPreferencesProvider.notifier).setEnabled(true);

      expect(container.read(notificationPreferencesProvider).enabled, true);
    });

    test('persists enabled=true to SharedPreferences', () async {
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);

      await container
          .read(notificationPreferencesProvider.notifier)
          .setEnabled(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled'), true);
    });

    test('persists enabled=false to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);

      await container
          .read(notificationPreferencesProvider.notifier)
          .setEnabled(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled'), false);
    });

    test('round-trip: persisted value is loaded by a fresh provider', () async {
      final first = _makeContainer();
      first.read(notificationPreferencesProvider);
      await first
          .read(notificationPreferencesProvider.notifier)
          .setEnabled(true);

      final second = _makeContainer();
      second.read(notificationPreferencesProvider);
      await Future.delayed(Duration.zero);

      expect(second.read(notificationPreferencesProvider).enabled, true);
    });
  });

  // ── setTime() ─────────────────────────────────────────────────────────────

  group('setTime()', () {
    test('updates state synchronously', () {
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);

      container
          .read(notificationPreferencesProvider.notifier)
          .setTime(const TimeOfDay(hour: 19, minute: 0));

      expect(
        container.read(notificationPreferencesProvider).reminderTime,
        const TimeOfDay(hour: 19, minute: 0),
      );
    });

    test('persists hour and minute to SharedPreferences', () async {
      final container = _makeContainer();
      container.read(notificationPreferencesProvider);

      await container
          .read(notificationPreferencesProvider.notifier)
          .setTime(const TimeOfDay(hour: 9, minute: 30));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('notifications_hour'), 9);
      expect(prefs.getInt('notifications_minute'), 30);
    });

    test('round-trip: persisted time is loaded by a fresh provider', () async {
      final first = _makeContainer();
      first.read(notificationPreferencesProvider);
      await first
          .read(notificationPreferencesProvider.notifier)
          .setTime(const TimeOfDay(hour: 21, minute: 15));

      final second = _makeContainer();
      second.read(notificationPreferencesProvider);
      await Future.delayed(Duration.zero);

      expect(
        second.read(notificationPreferencesProvider).reminderTime,
        const TimeOfDay(hour: 21, minute: 15),
      );
    });
  });
}
