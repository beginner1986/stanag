import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/providers/purchase_provider.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  bool _isLoading = false;

  Future<void> _subscribe(Package package) async {
    setState(() => _isLoading = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(purchaseServiceProvider).purchasePackage(package);
      await ref.read(authServiceProvider).refreshToken();
      if (mounted) context.pop();
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) return;
      if (mounted) _showSnackBar(l.upgradeErrorMessage);
    } catch (_) {
      if (mounted) _showSnackBar(l.upgradeErrorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(purchaseServiceProvider).restorePurchases();
      await ref.read(authServiceProvider).refreshToken();
      if (mounted) _showSnackBar(l.upgradeSuccessMessage);
    } catch (_) {
      if (mounted) _showSnackBar(l.upgradeErrorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.upgradeTitle)),
      body: offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l.upgradeErrorMessage)),
        data: (offerings) {
          final package = offerings.current?.monthly;
          return _UpgradeBody(
            package: package,
            isLoading: _isLoading,
            onSubscribe: package != null ? () => _subscribe(package) : null,
            onRestore: _restore,
          );
        },
      ),
    );
  }
}

class _UpgradeBody extends StatelessWidget {
  const _UpgradeBody({
    required this.package,
    required this.isLoading,
    required this.onSubscribe,
    required this.onRestore,
  });

  final Package? package;
  final bool isLoading;
  final VoidCallback? onSubscribe;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.upgradeSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _FeatureTile(
            icon: Icons.assignment_outlined,
            color: colorScheme.primary,
            title: l.upgradeMockExamsTitle,
            description: l.upgradeMockExamsDesc,
          ),
          _FeatureTile(
            icon: Icons.all_inclusive_outlined,
            color: colorScheme.primary,
            title: l.upgradeUnlimitedTitle,
            description: l.upgradeUnlimitedDesc,
          ),
          _FeatureTile(
            icon: Icons.block_outlined,
            color: colorScheme.primary,
            title: l.upgradeAdFreeTitle,
            description: l.upgradeAdFreeDesc,
          ),
          _FeatureTile(
            icon: Icons.download_outlined,
            color: colorScheme.primary,
            title: l.upgradeOfflineTitle,
            description: l.upgradeOfflineDesc,
          ),
          const SizedBox(height: 32),
          if (package != null)
            Text(
              l.upgradePricePerMonth(package!.storeProduct.priceString),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isLoading ? null : onSubscribe,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.upgradeSubscribeButton),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : onRestore,
            child: Text(l.upgradeRestoreButton),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(description,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
