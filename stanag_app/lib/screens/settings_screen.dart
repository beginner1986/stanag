import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    await ref.read(authServiceProvider).signInAnonymously();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final userState = ref.watch(userStateProvider);
    final email = ref.read(authServiceProvider).currentUser?.email;
    final isRegistered = userState.asData?.value != UserState.anonymous;

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
          _SectionHeader(l.settingsAccountSection),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(isRegistered && email != null ? email : l.settingsGuest),
          ),
          if (isRegistered)
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l.settingsSignOut),
              onTap: () => _signOut(ref),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.settingsPrivacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.settingsTerms),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {},
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
