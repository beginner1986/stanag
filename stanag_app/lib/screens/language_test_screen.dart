import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/locale_provider.dart';

class LanguageTestScreen extends ConsumerWidget {
  const LanguageTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Center(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.languageName),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref
                  .read(localeProvider.notifier)
                  .setLocale(const Locale('pl')),
                child: const Text('Polski')
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref
                  .read(localeProvider.notifier)
                  .setLocale(const Locale('en')),
                child: const Text('English')
              )
            ],
          )
        ),
      ),
    );
  }
}