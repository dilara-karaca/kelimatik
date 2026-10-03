import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../core/config/billing_config.dart';

/// Maps Play [ProductDetails] onto our subscription product IDs.
///
/// Monthly keeps the paid base plan. Yearly prefers a free-trial offer when
/// Play returns one for this user, and falls back to the paid base plan when
/// the account is no longer eligible.
abstract final class BillingProductIndex {
  static String idOf(ProductDetails product) {
    if (product is GooglePlayProductDetails) {
      final productId = product.productDetails.productId;
      if (productId.isNotEmpty) return productId;
    }
    return product.id;
  }

  static Map<String, ProductDetails> fromDetails(Iterable<ProductDetails> list) {
    final grouped = <String, List<ProductDetails>>{};
    for (final product in list) {
      grouped.putIfAbsent(idOf(product), () => []).add(product);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: preferOffer(entry.key, entry.value),
    };
  }

  static ProductDetails preferOffer(String productId, List<ProductDetails> options) {
    final wantedBasePlan = switch (productId) {
      BillingConfig.monthlyProductId => BillingConfig.monthlyBasePlanId,
      BillingConfig.yearlyProductId => BillingConfig.yearlyBasePlanId,
      _ => null,
    };

    ProductDetails? trialOffer;
    ProductDetails? matchingBasePlan;
    ProductDetails? anyBasePlan;

    for (final product in options) {
      if (product is! GooglePlayProductDetails) continue;
      final index = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null || index >= offers.length) continue;
      final offer = offers[index];
      final isBaseOffer = offer.offerId == null;
      if (wantedBasePlan != null && offer.basePlanId == wantedBasePlan) {
        if (productId == BillingConfig.yearlyProductId &&
            hasFreeTrial(offer)) {
          trialOffer ??= product;
        }
        if (isBaseOffer) matchingBasePlan ??= product;
      }
      if (isBaseOffer) anyBasePlan ??= product;
    }

    return trialOffer ?? matchingBasePlan ?? anyBasePlan ?? options.first;
  }

  /// A trial offer has a free phase and a later paid phase.
  static bool hasFreeTrial(SubscriptionOfferDetailsWrapper offer) {
    final phases = offer.pricingPhases;
    return phases.any((phase) => phase.priceAmountMicros == 0) &&
        phases.any((phase) => phase.priceAmountMicros > 0);
  }

  static SubscriptionOfferDetailsWrapper? selectedOffer(ProductDetails product) {
    if (product is! GooglePlayProductDetails) return null;
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    return offers[index];
  }
}
