import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kelimatik/core/config/billing_config.dart';
import 'package:kelimatik/data/services/billing/billing_purchase_outcome.dart';
import 'package:kelimatik/data/services/billing/billing_result.dart';

void main() {
  test('dismissed Play sheet finishes as canceled without touching Premium', () {
    final outcome = interpretPurchaseUpdates(
      [_purchase(productId: '', status: PurchaseStatus.canceled)],
      isLiveUpdate: true,
    );

    expect(outcome.subscribeStatus, BillingSubscribeStatus.canceled);
    expect(outcome.premiumActive, isNull);
  });

  test('monthly purchase activates Premium', () {
    final outcome = interpretPurchaseUpdates(
      [
        _purchase(
          productId: BillingConfig.monthlyProductId,
          status: PurchaseStatus.purchased,
        ),
      ],
      isLiveUpdate: true,
    );

    expect(outcome.premiumActive, isTrue);
    expect(outcome.subscribeStatus, BillingSubscribeStatus.success);
    expect(outcome.ownedProductId, BillingConfig.monthlyProductId);
  });

  test('restore with no subscription clears Premium', () {
    final outcome = interpretPurchaseUpdates(
      const [],
      isLiveUpdate: false,
    );

    expect(outcome.premiumActive, isFalse);
    expect(outcome.subscribeStatus, isNull);
  });

  test('empty live update does not clear Premium or finish a purchase', () {
    final outcome = interpretPurchaseUpdates(
      const [],
      isLiveUpdate: true,
    );

    expect(outcome.premiumActive, isNull);
    expect(outcome.subscribeStatus, isNull);
  });

  test('cancel of the monthly product does not deactivate Premium', () {
    final outcome = interpretPurchaseUpdates(
      [
        _purchase(
          productId: BillingConfig.monthlyProductId,
          status: PurchaseStatus.canceled,
        ),
      ],
      isLiveUpdate: true,
    );

    expect(outcome.subscribeStatus, BillingSubscribeStatus.canceled);
    expect(outcome.premiumActive, isNull);
  });

  test('item already owned on the monthly product counts as active', () {
    final outcome = interpretPurchaseUpdates(
      [
        _purchase(
          productId: BillingConfig.monthlyProductId,
          status: PurchaseStatus.error,
          error: IAPError(
            source: 'google_play',
            code: '7',
            message: 'Item already owned',
          ),
        ),
      ],
      isLiveUpdate: true,
    );

    expect(outcome.premiumActive, isTrue);
    expect(outcome.ownedProductId, BillingConfig.monthlyProductId);
  });
}

PurchaseDetails _purchase({
  required String productId,
  required PurchaseStatus status,
  IAPError? error,
}) {
  return PurchaseDetails(
    purchaseID: 'order',
    productID: productId,
    status: status,
    transactionDate: null,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: 'token',
      source: 'google_play',
    ),
  )..error = error;
}
