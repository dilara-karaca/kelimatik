import 'package:flutter/foundation.dart';

/// Central AdMob IDs for Kelimatik.
///
/// Debug / profile → Google **test** unit IDs (never real inventory).
/// Release → production unit IDs below.
///
/// AndroidManifest / Info.plist App ID must stay valid; use the Google test
/// App ID while developing. Before Play Store release, replace the manifest
/// App ID with your real AdMob **App** ID (`ca-app-pub-…~…`).
abstract final class AdMobConfig {
  /// `true` outside release builds so debug never requests real ads.
  static bool get useTestAds => !kReleaseMode;

  // ---------------------------------------------------------------------------
  // Production ad units (AdMob console) — Android
  // ---------------------------------------------------------------------------

  /// Production AdMob App ID (Android).
  static const String productionAndroidAppId =
      'ca-app-pub-3385068294638701~5347513217';
  static const String productionIosAppId =
      'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

  /// Kelimatik_Banner
  static const String productionAndroidBannerId =
      'ca-app-pub-3385068294638701/9955329295';

  /// Kelimatik_Interstitial
  static const String productionAndroidInterstitialId =
      'ca-app-pub-3385068294638701/6897870783';

  /// Kelimatik_Rewarded (+1 Can)
  static const String productionAndroidRewardedId =
      'ca-app-pub-3385068294638701/4062351707';

  // iOS unit IDs not provided yet — keep placeholders; release+iOS falls back
  // via [useTestAds] only when Android IDs are used from Android builds.
  static const String productionIosBannerId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String productionIosInterstitialId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String productionIosRewardedId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // ---------------------------------------------------------------------------
  // Google official test IDs
  // https://developers.google.com/admob/android/test-ads
  // ---------------------------------------------------------------------------

  static const String testAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String testIosAppId =
      'ca-app-pub-3940256099942544~1458002511';

  static const String testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testIosBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String testAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String testAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testIosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String get appId {
    if (useTestAds) {
      return _isIos ? testIosAppId : testAndroidAppId;
    }
    return _isIos ? productionIosAppId : productionAndroidAppId;
  }

  static String get bannerAdUnitId {
    if (useTestAds) {
      return _isIos ? testIosBannerId : testAndroidBannerId;
    }
    return _isIos ? productionIosBannerId : productionAndroidBannerId;
  }

  static String get interstitialAdUnitId {
    if (useTestAds) {
      return _isIos ? testIosInterstitialId : testAndroidInterstitialId;
    }
    return _isIos
        ? productionIosInterstitialId
        : productionAndroidInterstitialId;
  }

  static String get rewardedAdUnitId {
    if (useTestAds) {
      return _isIos ? testIosRewardedId : testAndroidRewardedId;
    }
    return _isIos ? productionIosRewardedId : productionAndroidRewardedId;
  }
}
