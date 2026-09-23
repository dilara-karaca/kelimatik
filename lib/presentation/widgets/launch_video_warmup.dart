import 'dart:async';

import 'package:video_player/video_player.dart';

/// Starts decoding the launch video as early as possible (from [main]).
///
/// One controller, one [initialize] call. [LaunchVideoSplash] only plays it.
abstract final class LaunchVideoWarmup {
  static const assetPath = 'assets/videos/giris.mp4';

  static VideoPlayerController? controller;
  static Future<bool>? initializing;

  static final Completer<void> decodeIdle = Completer<void>();

  static Future<bool> start() {
    return initializing ??= () async {
      try {
        return await _open().timeout(const Duration(seconds: 3));
      } on TimeoutException {
        return false;
      }
    }();
  }

  static Future<bool> _open() async {
    try {
      final player = VideoPlayerController.asset(assetPath);
      controller = player;
      await player.initialize();
      if (!player.value.isInitialized || player.value.hasError) {
        return false;
      }
      await player.setLooping(false);
      await player.setVolume(0);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lets AdMob / billing / sound warmup start after playback is done.
  static void markDecodeIdle() {
    if (!decodeIdle.isCompleted) {
      decodeIdle.complete();
    }
  }

  static void disposeController() {
    final player = controller;
    controller = null;
    initializing = null;
    player?.dispose();
  }
}
