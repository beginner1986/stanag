import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stanag_app/screens/language_test_screen.dart';
import 'package:stanag_app/services/auth_service.dart';
import 'package:stanag_app/services/user_service.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_staging.dart' as staging;
import 'firebase_options_prod.dart' as prod;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/locale_provider.dart';

const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = switch (flavor) {
    'staging' => staging.DefaultFirebaseOptions.currentPlatform,
    'prod' => prod.DefaultFirebaseOptions.currentPlatform,
    _ => dev.DefaultFirebaseOptions.currentPlatform
  };

  await Firebase.initializeApp(options: options);

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  await AuthService(FirebaseAuth.instance).signInAnonymously();

  final user = auth.currentUser;
  if (user != null) {
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final interfaceLang = deviceLang == 'pl' ? 'pl' : 'en';
    try {
      await UserService(firestore).createUserDocumentIfNeeded(
        user.uid,
        interfaceLang: interfaceLang,
      );
    } catch (_) {
      // Document creation will be retried on next launch.
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pl'),
      ],
      home: const LanguageTestScreen(),
    );
  }
}

