import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/notification_preferences_provider.dart';
import 'package:stanag_app/services/notification_permission_service.dart';

class NotificationSettingsTile extends ConsumerStatefulWidget {
  const NotificationSettingsTile({super.key});

  @override
  ConsumerState<NotificationSettingsTile> createState() =>
      _NotificationSettingsTileState();
}

class _NotificationSettingsTileState
    extends ConsumerState<NotificationSettingsTile> {
  Future<void> _handleToggle(bool value) async {
    final l = AppLocalizations.of(context)!;

    if (!value) {
      await ref.read(notificationPreferencesProvider.notifier).setEnabled(false);
      return;
    }

    final permService = ref.read(notificationPermissionServiceProvider);
    final status = await permService.checkStatus();

    if (status == NotificationPermissionStatus.granted) {
      await ref.read(notificationPreferencesProvider.notifier).setEnabled(true);
      return;
    }

    if (status == NotificationPermissionStatus.permanentlyDenied) {
      if (!mounted) return;
      _showPermanentlyDeniedSnackBar(l);
      return;
    }

    final result = await permService.request();
    if (!mounted) return;

    if (result == NotificationPermissionStatus.granted) {
      await ref.read(notificationPreferencesProvider.notifier).setEnabled(true);
    } else if (result == NotificationPermissionStatus.permanentlyDenied) {
      _showPermanentlyDeniedSnackBar(l);
    }
    // plain denied: toggle stays off silently
  }

  void _showPermanentlyDeniedSnackBar(AppLocalizations l) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.settingsNotificationsDenied),
        action: SnackBarAction(
          label: l.settingsNotificationsOpenSettings,
          onPressed: () =>
              ref.read(notificationPermissionServiceProvider).openSettings(),
        ),
      ),
    );
  }

  Future<void> _handleTimeTap() async {
    final prefs = ref.read(notificationPreferencesProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: prefs.reminderTime,
    );
    if (picked != null) {
      await ref.read(notificationPreferencesProvider.notifier).setTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final notifPrefs = ref.watch(notificationPreferencesProvider);

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(l.settingsNotificationsDailyReminder),
          value: notifPrefs.enabled,
          onChanged: _handleToggle,
        ),
        if (notifPrefs.enabled)
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(l.settingsNotificationsTime),
            trailing: Text(
              notifPrefs.reminderTime.format(context),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: _handleTimeTap,
          ),
      ],
    );
  }
}
