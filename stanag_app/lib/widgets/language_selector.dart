import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/providers/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Padding(
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
    );
  }
}
