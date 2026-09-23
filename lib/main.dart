import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/admob_bootstrap.dart';
import 'core/config/supabase_bootstrap.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/quiz_sounds.dart';
import 'presentation/providers/ads_provider.dart';
import 'presentation/providers/billing_provider.dart';
import 'presentation/providers/dependency_providers.dart';
import 'presentation/widgets/launch_video_warmup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Decode the splash video while Supabase / prefs boot — do not await.
  unawaited(LaunchVideoWarmup.start());

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
    // Listen to Play purchaseStream before the first frame.
    ref.read(billingProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareAfterSplash());
    });
  }

  Future<void> _prepareAfterSplash() async {
    try {
      await LaunchVideoWarmup.decodeIdle.future.timeout(
        const Duration(seconds: 6),
      );
    } on TimeoutException {
      LaunchVideoWarmup.markDecodeIdle();
    }
    if (!mounted) return;
    unawaited(QuizSounds.warmUp());
    unawaited(_prepareAds());
    unawaited(_prepareBilling());
  }

  Future<void> _prepareAds() async {
    await AdMobBootstrap.initialize();
    if (!mounted) return;
    if (AdMobBootstrap.isInitialized) {
      ref.read(adServiceProvider).preloadFullScreenAds();
    }
  }

  Future<void> _prepareBilling() async {
    await ref.read(billingProvider.notifier).bootstrap();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
