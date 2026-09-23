import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import 'launch_video_warmup.dart';

/// Full-screen cold-start video. Plays once, then holds the last frame.
class LaunchVideoSplash extends StatefulWidget {
  const LaunchVideoSplash({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<LaunchVideoSplash> createState() => _LaunchVideoSplashState();
}

class _LaunchVideoSplashState extends State<LaunchVideoSplash> {
  VideoPlayerController? _controller;
  var _ownsController = false;
  var _showPlayer = false;
  var _finished = false;
  Timer? _endTimer;
  Timer? _failsafe;

  @override
  void initState() {
    super.initState();
    _failsafe = Timer(const Duration(seconds: 5), _finish);
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final warmed = await LaunchVideoWarmup.start().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (!mounted || _finished) return;

      var player = LaunchVideoWarmup.controller;
      if (!warmed || player == null || !player.value.isInitialized) {
        final stale = LaunchVideoWarmup.controller;
        LaunchVideoWarmup.controller = null;
        LaunchVideoWarmup.initializing = null;
        unawaited(stale?.dispose());
        player = VideoPlayerController.asset(LaunchVideoWarmup.assetPath);
        _ownsController = true;
        _controller = player;
        await player.initialize().timeout(const Duration(seconds: 3));
        if (!mounted || _finished) return;
        await player.setLooping(false);
        await player.setVolume(0);
      } else {
        _controller = player;
      }

      if (!player.value.isInitialized || player.value.hasError) {
        _finish();
        return;
      }

      await player.setLooping(false);
      await player.setVolume(0);

      final duration = player.value.duration;
      if (duration <= Duration.zero) {
        setState(() => _showPlayer = true);
        await player.play();
        _finish();
        return;
      }

      _endTimer?.cancel();
      _endTimer = Timer(duration, () {
        unawaited(_controller?.pause());
        _finish();
      });

      if (!mounted || _finished) return;
      setState(() => _showPlayer = true);
      await player.play();
    } catch (_) {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _endTimer?.cancel();
    _failsafe?.cancel();
    LaunchVideoWarmup.markDecodeIdle();
    if (!mounted) {
      widget.onFinished();
      return;
    }
    widget.onFinished();
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    _failsafe?.cancel();
    LaunchVideoWarmup.markDecodeIdle();
    if (_ownsController) {
      _controller?.dispose();
    } else {
      LaunchVideoWarmup.disposeController();
    }
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _controller;
    final ready = _showPlayer &&
        player != null &&
        player.value.isInitialized &&
        player.value.size.width > 0;

    return ColoredBox(
      color: AppColors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _LaunchPlaceholder(),
          if (ready)
            RepaintBoundary(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: player.value.size.width,
                    height: player.value.size.height,
                    child: VideoPlayer(player),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LaunchPlaceholder extends StatelessWidget {
  const _LaunchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Center(
        child: Image.asset(
          AppIcons.logo,
          width: 128,
          height: 128,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
