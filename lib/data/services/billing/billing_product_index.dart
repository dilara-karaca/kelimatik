import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../core/config/billing_config.dart';

/// Maps Play [ProductDetails] onto our subscription product IDs.
///
/// Play can return several offers for one product ID. We keep the base-plan
/// offer that matches [BillingConfig], not a trial or intro offer.
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
        if (isBaseOffer) return product;
        matchingBasePlan ??= product;
      }
      if (isBaseOffer) anyBasePlan ??= product;
    }

    return matchingBasePlan ?? anyBasePlan ?? options.first;
  }
}
