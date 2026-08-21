import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/admob_bootstrap.dart';
import 'core/config/supabase_bootstrap.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/ads_provider.dart';
import 'presentation/providers/dependency_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseBootstrap.initialize();

  // AdMob + UMP run after first frame so the UI is not blocked on consent.
  // See [_AdsBootstrap].

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _AdsBootstrap(
        child: KelimatikApp(),
      ),
    ),
  );
}

/// UMP consent → Mobile Ads init → rewarded preload (non-blocking for first paint).
class _AdsBootstrap extends ConsumerStatefulWidget {
  const _AdsBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_AdsBootstrap> createState() => _AdsBootstrapState();
}

class _AdsBootstrapState extends ConsumerState<_AdsBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareAds());
    });
  }

  Future<void> _prepareAds() async {
    await AdMobBootstrap.initialize();
    if (!mounted) return;
    if (AdMobBootstrap.isInitialized) {
      ref.read(adServiceProvider).preloadFullScreenAds();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
