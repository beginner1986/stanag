import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesBootstrap {
  static Future<void> initialize({
    required String? userId,
    required String apiKey,
    required String flavor,
  }) async {
    if (apiKey.isEmpty || kIsWeb) return;
    if (flavor == 'dev') await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config).timeout(const Duration(seconds: 10));
  }
}
