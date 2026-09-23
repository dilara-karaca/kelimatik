import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/data/services/billing/billing_price_format.dart';

void main() {
  test('formats TRY like the yearly fallback', () {
    expect(
      BillingPriceFormat.format(amount: 49.99, currencyCode: 'TRY'),
      '49,99 TL',
    );
    expect(
      BillingPriceFormat.format(amount: 399.99, currencyCode: 'TRY'),
      '399,99 TL',
    );
  });
}
