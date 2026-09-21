import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:kelimatik/core/config/billing_config.dart';
import 'package:kelimatik/data/services/billing/billing_product_index.dart';

void main() {
  test('indexes monthly product by Play product ID, not base plan ID', () {
    final offers = GooglePlayProductDetails.fromProductDetails(
      _subscription(
        productId: BillingConfig.monthlyProductId,
        offers: [
          _offer(
            basePlanId: BillingConfig.monthlyBasePlanId,
            token: 'monthly-base',
            price: '₺49,99',
          ),
        ],
      ),
    );

    final indexed = BillingProductIndex.fromDetails(offers);

    expect(indexed.keys, [BillingConfig.monthlyProductId]);
    expect(indexed[BillingConfig.monthlyProductId]?.price, '₺49,99');
  });

  test('prefers the monthly base plan over a trial offer', () {
    final offers = GooglePlayProductDetails.fromProductDetails(
      _subscription(
        productId: BillingConfig.monthlyProductId,
        offers: [
          _offer(
            basePlanId: BillingConfig.monthlyBasePlanId,
            offerId: 'trial',
            token: 'monthly-trial',
            price: 'Free',
          ),
          _offer(
            basePlanId: BillingConfig.monthlyBasePlanId,
            token: 'monthly-base',
            price: '₺49,99',
          ),
        ],
      ),
    );

    final indexed = BillingProductIndex.fromDetails(offers);
    final selected = indexed[BillingConfig.monthlyProductId];

    expect(selected, isA<GooglePlayProductDetails>());
    expect(
      (selected! as GooglePlayProductDetails).offerToken,
      'monthly-base',
    );
  });
}

ProductDetailsWrapper _subscription({
  required String productId,
  required List<SubscriptionOfferDetailsWrapper> offers,
}) {
  return ProductDetailsWrapper(
    description: 'Premium',
    name: 'Premium',
    productId: productId,
    productType: ProductType.subs,
    title: 'Premium',
    subscriptionOfferDetails: offers,
  );
}

SubscriptionOfferDetailsWrapper _offer({
  required String basePlanId,
  required String token,
  required String price,
  String? offerId,
}) {
  return SubscriptionOfferDetailsWrapper(
    basePlanId: basePlanId,
    offerId: offerId,
    offerTags: const [],
    offerIdToken: token,
    pricingPhases: [
      PricingPhaseWrapper(
        billingCycleCount: 0,
        billingPeriod: 'P1M',
        formattedPrice: price,
        priceAmountMicros: 49990000,
        priceCurrencyCode: 'TRY',
        recurrenceMode: RecurrenceMode.infiniteRecurring,
      ),
    ],
  );
}
