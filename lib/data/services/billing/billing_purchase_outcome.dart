import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/config/billing_config.dart';
import 'billing_result.dart';

/// What a Play purchase or restore batch means for Premium.
///
/// [premiumActive] is null when this batch must not change the local flag
/// (a canceled sheet, a pending payment, or an empty live update).
class BillingPurchaseOutcome {
  const BillingPurchaseOutcome({
    this.premiumActive,
    this.subscribeStatus,
    this.ownedProductId,
  });

  final bool? premiumActive;
  final BillingSubscribeStatus? subscribeStatus;
  final String? ownedProductId;
}

/// Interprets a purchaseStream or restore batch.
///
/// Play's Android plugin reports a dismissed billing sheet as one
/// [PurchaseDetails] with an empty product id and [PurchaseStatus.canceled].
/// That update still has to finish the in-flight purchase; otherwise the
/// subscribe button waits forever.
BillingPurchaseOutcome interpretPurchaseUpdates(
  List<PurchaseDetails> purchases, {
  required bool isLiveUpdate,
}) {
  var hasPremium = false;
  var sawPending = false;
  var sawCanceled = false;
  var sawError = false;
  IAPError? lastError;
  String? ownedProductId;

  for (final purchase in purchases) {
    if (!BillingConfig.isPremiumProductId(purchase.productID)) {
      if (purchase.productID.isEmpty) {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            sawPending = true;
          case PurchaseStatus.canceled:
            sawCanceled = true;
          case PurchaseStatus.error:
            sawError = true;
            lastError = purchase.error;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            break;
        }
      }
      continue;
    }

    switch (purchase.status) {
      case PurchaseStatus.pending:
        sawPending = true;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        hasPremium = true;
        ownedProductId = purchase.productID;
      case PurchaseStatus.canceled:
        sawCanceled = true;
      case PurchaseStatus.error:
        sawError = true;
        lastError = purchase.error;
        if (isAlreadyOwnedIapError(purchase.error)) {
          hasPremium = true;
          ownedProductId = purchase.productID;
        }
    }
  }

  if (hasPremium) {
    return BillingPurchaseOutcome(
      premiumActive: true,
      subscribeStatus: BillingSubscribeStatus.success,
      ownedProductId: ownedProductId,
    );
  }

  if (isLiveUpdate) {
    if (sawPending) {
      return const BillingPurchaseOutcome(
        subscribeStatus: BillingSubscribeStatus.pending,
      );
    }
    if (sawCanceled) {
      return const BillingPurchaseOutcome(
        subscribeStatus: BillingSubscribeStatus.canceled,
      );
    }
    if (sawError) {
      final status = lastError != null && isNetworkIapError(lastError)
          ? BillingSubscribeStatus.networkError
          : BillingSubscribeStatus.error;
      return BillingPurchaseOutcome(subscribeStatus: status);
    }
    return const BillingPurchaseOutcome();
  }

  return const BillingPurchaseOutcome(premiumActive: false);
}

bool isAlreadyOwnedIapError(IAPError? error) {
  if (error == null) return false;
  final blob = '${error.code} ${error.message}'.toLowerCase();
  return blob.contains('alreadyowned') ||
      blob.contains('already owned') ||
      blob.contains('item_already_owned') ||
      error.code == '7';
}

bool isNetworkIapError(IAPError error) {
  final blob = '${error.code} ${error.message}'.toLowerCase();
  return blob.contains('network') ||
      blob.contains('service_timeout') ||
      blob.contains('service_unavailable') ||
      blob.contains('billing_unavailable') ||
      blob.contains('timeout');
}
