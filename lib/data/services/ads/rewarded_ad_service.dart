import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/admob_bootstrap.dart';
import '../../../core/config/admob_config.dart';

/// Result of attempting to show a rewarded ad.
enum RewardedAdShowResult {
  /// User watched fully; [onUserEarnedReward] fired.
  rewarded,

  /// Ad was shown but user closed early — no reward.
  dismissedWithoutReward,

  /// Nothing to show (not loaded / SDK not ready / show failed).
  unavailable,
}

/// Loads and shows rewarded ads. Reward only when the user completes the ad.
class RewardedAdService {
  RewardedAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;

  bool get isReady => _ad != null && !_isShowing;
  bool get isShowing => _isShowing;

  Future<void> preload() async {
    if (!AdMobBootstrap.isInitialized) return;
    if (_ad != null || _isLoading || _isShowing) return;

    _isLoading = true;
    try {
      await RewardedAd.load(
        adUnitId: AdMobConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _isLoading = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded failed to load: $error');
            _ad = null;
            _isLoading = false;
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Rewarded load error: $e\n$st');
      _ad = null;
      _isLoading = false;
    }
  }

  /// Shows a rewarded ad when ready.
  ///
  /// [onUserEarnedReward] runs only after AdMob confirms a full watch
  /// (never when the user abandons mid-ad).
  Future<RewardedAdShowResult> show({
    FutureOr<void> Function()? onUserEarnedReward,
  }) async {
    final ad = _ad;
    if (ad == null || _isShowing) {
      preload();
      return RewardedAdShowResult.unavailable;
    }

    _ad = null;
    _isShowing = true;
    var earned = false;
    final completer = Completer<RewardedAdShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        preload();
        if (!completer.isCompleted) {
          completer.complete(
            earned
                ? RewardedAdShowResult.rewarded
                : RewardedAdShowResult.dismissedWithoutReward,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded failed to show: $error');
        ad.dispose();
        _isShowing = false;
        preload();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdShowResult.unavailable);
        }
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) async {
          earned = true;
          try {
            await onUserEarnedReward?.call();
          } catch (e, st) {
            debugPrint('Rewarded callback error: $e\n$st');
          }
        },
      );
    } catch (e, st) {
      debugPrint('Rewarded show error: $e\n$st');
      ad.dispose();
      _isShowing = false;
      preload();
      return RewardedAdShowResult.unavailable;
    }

    return completer.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoading = false;
    _isShowing = false;
  }
}
