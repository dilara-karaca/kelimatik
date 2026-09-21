import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/ads/ad_service.dart';
import 'premium_provider.dart';

/// Shared AdMob facade (interstitial + rewarded). Banner uses [AdBanner].
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService(
    isPremium: () => ref.read(premiumProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
