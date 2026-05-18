import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stanag_app/services/purchase_service.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return RevenueCatPurchaseService();
});

final offeringsProvider = FutureProvider<Offerings>((ref) async {
  return ref.read(purchaseServiceProvider).getOfferings();
});
