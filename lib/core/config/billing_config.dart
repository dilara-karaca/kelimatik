/// Google Play Billing product IDs for Kelimatik Premium.
///
/// Keep every Play product ID in this file. Do not scatter IDs across UI.
///
/// These values are the IDs the app queries. They must be created **exactly**
/// in Play Console before purchases can succeed:
/// Monetize → Products → Subscriptions.
abstract final class BillingConfig {
  static const String androidApplicationId = 'com.kelimatik.kelimatik';

  /// Play Console subscription product ID — monthly Premium.
  static const String monthlyProductId = 'premium_monthly';

  /// Play Console subscription product ID — yearly Premium.
  static const String yearlyProductId = 'kelimatik_premium_yearly';

  /// Monthly base plan ID to create under [monthlyProductId].
  static const String monthlyBasePlanId = 'monthly';

  /// Yearly base plan ID to create under [yearlyProductId].
  static const String yearlyBasePlanId = 'yearly';

  /// UI fallback when Play localized prices are not loaded yet.
  static const String fallbackMonthlyPrice = '49,99 TL';

  /// UI fallback when Play localized prices are not loaded yet.
  static const String fallbackYearlyPrice = '399,99 TL';

  static const Set<String> premiumProductIds = {
    monthlyProductId,
    yearlyProductId,
  };

  static bool isPremiumProductId(String productId) =>
      premiumProductIds.contains(productId);

  static Uri manageSubscriptionsUri({String? sku}) {
    return Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?package=$androidApplicationId'
      '${sku == null || sku.isEmpty ? '' : '&sku=$sku'}',
    );
  }
}
