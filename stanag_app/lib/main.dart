import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stanag_app/screens/language_test_screen.dart';
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

