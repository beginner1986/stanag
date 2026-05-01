import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stanag_app/models/notification_preferences.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? 8;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    state = NotificationPreferences(
      enabled: enabled,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
  }
}
