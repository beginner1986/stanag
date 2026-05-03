import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/providers/local_storage_provider.dart';

const _localeKey = 'interface_lang';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSavedLocale();
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale =
        await ref.read(localStorageProvider).getString(_localeKey);
    if (!ref.mounted) return;
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    await ref.read(localStorageProvider).setString(_localeKey, newLocale.languageCode);
  }
}
