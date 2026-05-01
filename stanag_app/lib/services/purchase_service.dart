import 'package:purchases_flutter/purchases_flutter.dart';

abstract class PurchaseService {
  Future<Offerings> getOfferings();
  Future<void> purchasePackage(Package package);
  Future<void> restorePurchases();
}

class RevenueCatPurchaseService implements PurchaseService {
  @override
  Future<Offerings> getOfferings() => Purchases.getOfferings();

  @override
  Future<void> purchasePackage(Package package) async {
    await Purchases.purchase(PurchaseParams.package(package));
  }

  @override
  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }
}
