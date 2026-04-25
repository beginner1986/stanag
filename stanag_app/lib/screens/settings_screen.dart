import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/providers/locale_provider.dart';
import 'package:stanag_app/providers/notification_preferences_provider.dart';
import 'package:stanag_app/services/notification_permission_service.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://stanag-english.app/privacy';
const _termsUrl = 'https://stanag-english.app/terms';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    await ref.read(authServiceProvider).signInAnonymously();
  }

  Future<void> _handleNotificationToggle(bool value) async {
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
    // plain denied: do nothing — toggle stays off silently
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

  String? _accountTypeLabel(UserState? state, AppLocalizations l) {
    return switch (state) {
      UserState.registeredFree => l.settingsAccountTypeFree,
      UserState.registeredPremium => l.settingsAccountTypePremium,
      UserState.expiredPremium => l.settingsAccountTypeExpired,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final userState = ref.watch(userStateProvider);
    final notifPrefs = ref.watch(notificationPreferencesProvider);
    final email = ref.read(authServiceProvider).currentUser?.email;
    final userStateValue = userState.asData?.value;
    final isRegistered = userStateValue != UserState.anonymous;
    final accountTypeLabel = _accountTypeLabel(userStateValue, l);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l.settingsLanguageSection),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'pl', label: Text('Polski')),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (selection) {
                ref.read(localeProvider.notifier).setLocale(Locale(selection.first));
              },
            ),
          ),
          const Divider(),
          _SectionHeader(l.settingsNotificationsSection),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l.settingsNotificationsDailyReminder),
            value: notifPrefs.enabled,
            onChanged: _handleNotificationToggle,
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
          const Divider(),
          _SectionHeader(l.settingsAccountSection),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(isRegistered && email != null ? email : l.settingsGuest),
            subtitle: accountTypeLabel != null ? Text(accountTypeLabel) : null,
          ),
          if (isRegistered)
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l.settingsSignOut),
              onTap: _signOut,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.settingsPrivacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl(_privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.settingsTerms),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl(_termsUrl),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
