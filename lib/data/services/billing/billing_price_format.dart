import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import 'billing_product_index.dart';

/// Formats Play prices like the Turkish fallbacks: `49,99 TL`.
abstract final class BillingPriceFormat {
  static String fromProduct(ProductDetails product) {
    final paid = _paidPhase(product);
    if (paid != null && paid.priceAmountMicros > 0) {
      return format(
        amount: paid.priceAmountMicros / 1000000,
        currencyCode: paid.priceCurrencyCode,
      );
    }
    if (product.rawPrice > 0) {
      return format(
        amount: product.rawPrice,
        currencyCode: product.currencyCode,
      );
    }
    return product.price;
  }

  /// "7 gün ücretsiz" when the selected yearly offer starts with a free phase.
  static String? freeTrialLabel(ProductDetails product) {
    final offer = BillingProductIndex.selectedOffer(product);
    if (offer == null || !BillingProductIndex.hasFreeTrial(offer)) return null;
    for (final phase in offer.pricingPhases) {
      if (phase.priceAmountMicros != 0) continue;
      final days = _periodDays(phase.billingPeriod);
      if (days == null) return 'Ücretsiz deneme';
      return '$days gün ücretsiz';
    }
    return null;
  }

  static PricingPhaseWrapper? _paidPhase(ProductDetails product) {
    final offer = BillingProductIndex.selectedOffer(product);
    if (offer == null) return null;
    for (final phase in offer.pricingPhases.reversed) {
      if (phase.priceAmountMicros > 0) return phase;
    }
    return null;
  }

  static int? _periodDays(String period) {
    final match = RegExp(r'^P(\d+)D$').firstMatch(period);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String format({
    required double amount,
    required String currencyCode,
  }) {
    final number = _trNumber(amount);
    final code = currencyCode.toUpperCase();
    if (code == 'TRY' || code == 'TL' || code == '₺') {
      return '$number TL';
    }
    return '$number $code';
  }

  static String _trNumber(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final frac = parts[1];
    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) {
        grouped.write('.');
      }
      grouped.write(whole[i]);
    }
    return '${grouped.toString()},$frac';
  }
}
