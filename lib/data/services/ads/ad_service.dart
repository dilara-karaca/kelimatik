import 'dart:async';

import 'interstitial_ad_service.dart';
import 'rewarded_ad_service.dart';

/// Facade over interstitial + rewarded ads.
///
/// Banner ads are owned by [AdBanner] widgets (each needs its own AdWidget).
class AdService {
  AdService({
    InterstitialAdService? interstitial,
    RewardedAdService? rewarded,
  })  : interstitial = interstitial ?? InterstitialAdService(),
        rewarded = rewarded ?? RewardedAdService();

  final InterstitialAdService interstitial;
  final RewardedAdService rewarded;

  bool get isRewardedReady => rewarded.isReady;
  bool get isInterstitialReady => interstitial.isReady;

  /// Preloads rewarded (used by out-of-lives). Interstitial stays on-demand
  /// so it is never forced into the game loop.
  void preloadFullScreenAds() {
    unawaited(rewarded.preload());
  }

  /// Call when an interstitial placement is wired (not used in game flow yet).
  void preloadInterstitial() {
    unawaited(interstitial.preload());
  }

  Future<bool> showInterstitialIfReady() => interstitial.showIfReady();

  /// Shows rewarded ad; [onUserEarnedReward] only after a complete watch.
  Future<RewardedAdShowResult> showRewarded({
    FutureOr<void> Function()? onUserEarnedReward,
  }) {
    return rewarded.show(onUserEarnedReward: onUserEarnedReward);
  }

  void dispose() {
    interstitial.dispose();
    rewarded.dispose();
  }
}
