import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/ads/ad_service.dart';

/// Shared AdMob facade (interstitial + rewarded). Banner uses [AdBanner].
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  ref.onDispose(service.dispose);
  return service;
});
