import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/admob_bootstrap.dart';
import '../../../core/config/admob_config.dart';

/// Loads and shows interstitial ads. Safe no-ops when ads are unavailable.
///
/// Call [preload] early; call [showIfReady] from a deliberate UX moment later.
/// Do not place interstitial triggers randomly in the UI yet.
class InterstitialAdService {
  InterstitialAd? _ad;
  bool _isLoading = false;

  bool get isReady => _ad != null;

  Future<void> preload() async {
    if (!AdMobBootstrap.isInitialized) return;
    if (_ad != null || _isLoading) return;

    _isLoading = true;
    try {
      await InterstitialAd.load(
        adUnitId: AdMobConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _isLoading = false;
            _attachCallbacks(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial failed to load: $error');
            _ad = null;
            _isLoading = false;
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Interstitial load error: $e\n$st');
      _ad = null;
      _isLoading = false;
    }
  }

  void _attachCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        _ad = null;
        preload();
      },
    );
  }

  /// Shows the ad when loaded. Returns `true` if show was started.
  Future<bool> showIfReady() async {
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }
    try {
      _ad = null;
      await ad.show();
      return true;
    } catch (e, st) {
      debugPrint('Interstitial show error: $e\n$st');
      ad.dispose();
      _ad = null;
      preload();
      return false;
    }
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoading = false;
  }
}
