import 'package:flutter/material.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/widgets/account_section.dart';
import 'package:stanag_app/widgets/language_selector.dart';
import 'package:stanag_app/widgets/notification_settings_tile.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://stanag-english.app/privacy';
const _termsUrl = 'https://stanag-english.app/terms';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l.settingsLanguageSection),
          const LanguageSelector(),
          const Divider(),
          _SectionHeader(l.settingsNotificationsSection),
          const NotificationSettingsTile(),
          const Divider(),
          _SectionHeader(l.settingsAccountSection),
          const AccountSection(),
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
