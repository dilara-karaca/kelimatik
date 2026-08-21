import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ump_consent_service.dart';

/// Initializes the Google Mobile Ads SDK once after UMP consent handling.
///
/// Failures are swallowed so ads never block app launch.
/// [isInitialized] is true only when ads may be requested ([canRequestAds]).
abstract final class AdMobBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// 1) Gather UMP consent (no-op form if not required)
  /// 2) Initialize Mobile Ads only when [UmpConsentService.canRequestAds]
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await UmpConsentService.gatherConsent();

      final canRequest = await UmpConsentService.canRequestAds();
      if (!canRequest) {
        debugPrint('AdMob: canRequestAds=false; skipping MobileAds.init');
        return;
      }

      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e, st) {
      debugPrint('AdMob initialize failed: $e\n$st');
      _initialized = false;
    }
  }
}
