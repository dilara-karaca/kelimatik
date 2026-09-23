import 'package:in_app_purchase/in_app_purchase.dart';

/// Formats Play prices like the Turkish fallbacks: `49,99 TL`.
abstract final class BillingPriceFormat {
  static String fromProduct(ProductDetails product) {
    if (product.rawPrice > 0) {
      return format(
        amount: product.rawPrice,
        currencyCode: product.currencyCode,
      );
    }
    return product.price;
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
