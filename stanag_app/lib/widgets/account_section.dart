import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/routes/app_routes.dart';

class AccountSection extends ConsumerStatefulWidget {
  const AccountSection({super.key});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  Future<void> _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
      await ref.read(authServiceProvider).signInAnonymously();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
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
    final userState = ref.watch(userStateProvider);
    final email = ref.read(authServiceProvider).currentUser?.email;
    final userStateValue = userState.asData?.value;
    final isRegistered = userStateValue != UserState.anonymous;
    final accountTypeLabel = _accountTypeLabel(userStateValue, l);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(isRegistered && email != null ? email : l.settingsGuest),
          subtitle: accountTypeLabel != null ? Text(accountTypeLabel) : null,
        ),
        if (userStateValue == UserState.registeredFree ||
            userStateValue == UserState.expiredPremium)
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(l.settingsUpgradeToPremium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.upgrade),
          ),
        if (isRegistered)
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l.settingsSignOut),
            onTap: _signOut,
          ),
      ],
    );
  }
}
