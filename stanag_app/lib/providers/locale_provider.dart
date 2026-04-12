import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'interface_lang';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(): super(const Locale('en')) {
    _loadSavedLocale();
  }

Future<void> _loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString(_localeKey);
  if (savedLocale != null) {
    state = Locale(savedLocale);
  }
}

  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }
}