import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/models/notification_preferences.dart';
import 'package:stanag_app/providers/local_storage_provider.dart';
import 'package:stanag_app/services/notification_permission_service.dart';

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>(
  (ref) => const LiveNotificationPermissionService(),
);

const _enabledKey = 'notifications_enabled';
const _hourKey = 'notifications_hour';
const _minuteKey = 'notifications_minute';

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() {
    _load();
    return const NotificationPreferences();
  }

  Future<void> _load() async {
    final storage = ref.read(localStorageProvider);
    final enabled = await storage.getBool(_enabledKey) ?? false;
    final hour = await storage.getInt(_hourKey) ?? 8;
    final minute = await storage.getInt(_minuteKey) ?? 0;
    if (!ref.mounted) return;
    state = NotificationPreferences(
      enabled: enabled,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await ref.read(localStorageProvider).setBool(_enabledKey, value);
  }

  Future<void> setTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    final storage = ref.read(localStorageProvider);
    await storage.setInt(_hourKey, time.hour);
    await storage.setInt(_minuteKey, time.minute);
  }
}
