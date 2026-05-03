import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/providers/local_storage_provider.dart';

const _localeKey = 'interface_lang';

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final saved = await ref.read(localStorageProvider).getString(_localeKey);
    return Locale(saved ?? 'en');
  }

  Future<void> setLocale(Locale newLocale) async {
    state = AsyncData(newLocale);
    await ref.read(localStorageProvider).setString(_localeKey, newLocale.languageCode);
  }
}
