import 'package:flutter/material.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = false,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
  });

  final bool enabled;
  final TimeOfDay reminderTime;

  NotificationPreferences copyWith({
    bool? enabled,
    TimeOfDay? reminderTime,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
