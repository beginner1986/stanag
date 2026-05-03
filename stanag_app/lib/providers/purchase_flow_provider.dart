import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/providers/purchase_provider.dart';

enum PurchaseFlowStatus { idle, loading, subscribed, restored, cancelled, error }

class PurchaseFlowState {
  const PurchaseFlowState({this.status = PurchaseFlowStatus.idle});
  final PurchaseFlowStatus status;
  bool get isLoading => status == PurchaseFlowStatus.loading;
}

class PurchaseFlowNotifier extends Notifier<PurchaseFlowState> {
  @override
  PurchaseFlowState build() => const PurchaseFlowState();

  Future<void> subscribe(Package package) async {
    state = const PurchaseFlowState(status: PurchaseFlowStatus.loading);
    try {
      await ref.read(purchaseServiceProvider).purchasePackage(package);
      await ref.read(authServiceProvider).refreshToken();
      state = const PurchaseFlowState(status: PurchaseFlowStatus.subscribed);
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        state = const PurchaseFlowState(status: PurchaseFlowStatus.cancelled);
        return;
      }
      debugPrint('PurchaseFlowNotifier: purchase error: $e');
      state = const PurchaseFlowState(status: PurchaseFlowStatus.error);
    } catch (e, st) {
      debugPrint('PurchaseFlowNotifier: unexpected error: $e\n$st');
      state = const PurchaseFlowState(status: PurchaseFlowStatus.error);
    }
  }

  Future<void> restore() async {
    state = const PurchaseFlowState(status: PurchaseFlowStatus.loading);
    try {
      await ref.read(purchaseServiceProvider).restorePurchases();
      await ref.read(authServiceProvider).refreshToken();
      state = const PurchaseFlowState(status: PurchaseFlowStatus.restored);
    } catch (e, st) {
      debugPrint('PurchaseFlowNotifier: restore error: $e\n$st');
      state = const PurchaseFlowState(status: PurchaseFlowStatus.error);
    }
  }
}

final purchaseFlowProvider =
    NotifierProvider<PurchaseFlowNotifier, PurchaseFlowState>(
  PurchaseFlowNotifier.new,
);
