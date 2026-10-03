import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:kelimatik/core/config/billing_config.dart';
import 'package:kelimatik/data/services/billing/billing_price_format.dart';
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

  test('yearly purchase uses the 7-day trial when Play offers it', () {
    final offers = GooglePlayProductDetails.fromProductDetails(
      _subscription(
        productId: BillingConfig.yearlyProductId,
        offers: [
          _offer(
            basePlanId: BillingConfig.yearlyBasePlanId,
            offerId: 'trial-7d',
            token: 'yearly-trial',
            price: 'Ücretsiz',
            billingPeriod: 'P7D',
            priceAmountMicros: 0,
            recurrenceMode: RecurrenceMode.finiteRecurring,
            billingCycleCount: 1,
            then: _phase(
              price: '₺399,99',
              billingPeriod: 'P1Y',
              priceAmountMicros: 399990000,
            ),
          ),
          _offer(
            basePlanId: BillingConfig.yearlyBasePlanId,
            token: 'yearly-base',
            price: '₺399,99',
            billingPeriod: 'P1Y',
            priceAmountMicros: 399990000,
          ),
        ],
      ),
    );

    final indexed = BillingProductIndex.fromDetails(offers);
    final selected = indexed[BillingConfig.yearlyProductId]!;

    expect((selected as GooglePlayProductDetails).offerToken, 'yearly-trial');
    expect(BillingPriceFormat.fromProduct(selected), '399,99 TL');
    expect(BillingPriceFormat.freeTrialLabel(selected), '7 gün ücretsiz');
  });

  test('yearly falls back to the paid base plan when no trial is offered', () {
    final offers = GooglePlayProductDetails.fromProductDetails(
      _subscription(
        productId: BillingConfig.yearlyProductId,
        offers: [
          _offer(
            basePlanId: BillingConfig.yearlyBasePlanId,
            token: 'yearly-base',
            price: '₺399,99',
            billingPeriod: 'P1Y',
            priceAmountMicros: 399990000,
          ),
        ],
      ),
    );

    final selected = BillingProductIndex.fromDetails(offers)[
        BillingConfig.yearlyProductId]!;

    expect((selected as GooglePlayProductDetails).offerToken, 'yearly-base');
    expect(BillingPriceFormat.freeTrialLabel(selected), isNull);
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
  String billingPeriod = 'P1M',
  int priceAmountMicros = 49990000,
  RecurrenceMode recurrenceMode = RecurrenceMode.infiniteRecurring,
  int billingCycleCount = 0,
  PricingPhaseWrapper? then,
}) {
  return SubscriptionOfferDetailsWrapper(
    basePlanId: basePlanId,
    offerId: offerId,
    offerTags: const [],
    offerIdToken: token,
    pricingPhases: [
      _phase(
        price: price,
        billingPeriod: billingPeriod,
        priceAmountMicros: priceAmountMicros,
        recurrenceMode: recurrenceMode,
        billingCycleCount: billingCycleCount,
      ),
      if (then != null) then,
    ],
  );
}

PricingPhaseWrapper _phase({
  required String price,
  required String billingPeriod,
  required int priceAmountMicros,
  RecurrenceMode recurrenceMode = RecurrenceMode.infiniteRecurring,
  int billingCycleCount = 0,
}) {
  return PricingPhaseWrapper(
    billingCycleCount: billingCycleCount,
    billingPeriod: billingPeriod,
    formattedPrice: price,
    priceAmountMicros: priceAmountMicros,
    priceCurrencyCode: 'TRY',
    recurrenceMode: recurrenceMode,
  );
}
