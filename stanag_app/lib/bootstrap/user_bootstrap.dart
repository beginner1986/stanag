import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:stanag_app/repositories/firebase/firebase_user_repository.dart';

class UserBootstrap {
  static Future<void> initialize(User? user) async {
    if (user == null) return;
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final interfaceLang = deviceLang == 'pl' ? 'pl' : 'en';
    try {
      await FirebaseUserRepository.live().createUserDocumentIfNeeded(
        user.uid,
        interfaceLang: interfaceLang,
      );
    } catch (_) {
      // Document creation will be retried on next launch.
    }
  }
}
