import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/admob_bootstrap.dart';
import '../../../core/config/admob_config.dart';

/// Reusable banner ad. Renders nothing until loaded (no empty reserved gap).
///
/// Place explicitly where needed — not wired into screens by default.
class AdBanner extends StatefulWidget {
  const AdBanner({
    super.key,
    this.size = AdSize.banner,
    this.margin,
  });

  final AdSize size;
  final EdgeInsetsGeometry? margin;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdMobBootstrap.isInitialized) return;
    if (kIsWeb) return;

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
