import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/core/config/billing_config.dart';

void main() {
  test('Premium product IDs stay centralized', () {
    expect(BillingConfig.monthlyProductId, 'premium_monthly');
    expect(BillingConfig.yearlyProductId, 'kelimatik_premium_yearly');
    expect(
      BillingConfig.isPremiumProductId(BillingConfig.monthlyProductId),
      isTrue,
    );
    expect(
      BillingConfig.isPremiumProductId(BillingConfig.yearlyProductId),
      isTrue,
    );
    expect(BillingConfig.isPremiumProductId('other'), isFalse);
  });

  test('manage-subscriptions URI points at this Android application id', () {
    final uri = BillingConfig.manageSubscriptionsUri(
      sku: BillingConfig.yearlyProductId,
    );
    expect(uri.host, 'play.google.com');
    expect(uri.queryParameters['package'], BillingConfig.androidApplicationId);
    expect(uri.queryParameters['sku'], BillingConfig.yearlyProductId);
  });
}
