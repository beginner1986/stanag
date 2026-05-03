import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/bootstrap/auth_bootstrap.dart';
import 'package:stanag_app/bootstrap/firebase_bootstrap.dart';
import 'package:stanag_app/bootstrap/purchases_bootstrap.dart';
import 'package:stanag_app/bootstrap/user_bootstrap.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/locale_provider.dart';
import 'package:stanag_app/providers/router_provider.dart';

const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
const String _revenueCatApiKey =
    String.fromEnvironment('REVENUECAT_API_KEY', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize(flavor);
  final user = await AuthBootstrap.initialize();
  await PurchasesBootstrap.initialize(
    userId: user?.uid,
    apiKey: _revenueCatApiKey,
    flavor: flavor,
  );
  await UserBootstrap.initialize(user);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
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
    );
  }
}
