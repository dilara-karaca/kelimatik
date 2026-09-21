import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/admob_bootstrap.dart';
import '../../../core/config/admob_config.dart';
import '../../providers/premium_provider.dart';

/// Reusable banner ad. Renders nothing until loaded (no empty reserved gap).
///
/// Place explicitly where needed — not wired into screens by default.
/// Hidden for Premium users; AdMob unit IDs are unchanged.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({
    super.key,
    this.size = AdSize.banner,
    this.margin,
  });

  final AdSize size;
  final EdgeInsetsGeometry? margin;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!ref.read(premiumProvider)) {
      _load();
    }
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
  }

  void _load() {
    if (!AdMobBootstrap.isInitialized) return;
    if (kIsWeb) return;
    if (ref.read(premiumProvider)) return;

    final banner = BannerAd(
      size: widget.size,
      adUnitId: AdMobConfig.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          if (ref.read(premiumProvider)) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _banner = null;
              _loaded = false;
            });
          }
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    ref.listen<bool>(premiumProvider, (previous, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _disposeBanner();
          if (mounted) setState(() {});
        });
      } else if (previous == true && !next) {
        _load();
      }
    });
    if (isPremium) {
      return const SizedBox.shrink();
    }

    final banner = _banner;
    if (!_loaded || banner == null) {
      return const SizedBox.shrink();
    }

    final child = SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );

    final margin = widget.margin;
    if (margin == null) return child;
    return Padding(padding: margin, child: child);
  }
}
