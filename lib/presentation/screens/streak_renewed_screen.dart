import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/streak_reward_cycle.dart';
import '../widgets/rolling_streak_number.dart';
import '../widgets/streak_cycle_bar.dart';

class StreakRenewedScreen extends StatefulWidget {
  const StreakRenewedScreen({
    super.key,
    required this.fromStreak,
    required this.toStreak,
  });

  static const videoAsset = 'assets/videos/seri_yenilendi.mp4';

  final int fromStreak;
  final int toStreak;

  @override
  State<StreakRenewedScreen> createState() => _StreakRenewedScreenState();
}

class _StreakRenewedScreenState extends State<StreakRenewedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;
  VideoPlayerController? _player;
  var _videoReady = false;
  var _videoFailed = false;

  late final Animation<double> _digits;
  late final Animation<double> _bar;
  late final Animation<double> _motto;

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _digits = CurvedAnimation(
      parent: _timeline,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    );
    _bar = CurvedAnimation(
      parent: _timeline,
      curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
    );
    _motto = CurvedAnimation(
      parent: _timeline,
      curve: const Interval(0.88, 1, curve: Curves.easeOut),
    );
    unawaited(_startVideo());
  }

  Future<void> _startVideo() async {
    VideoPlayerController? player;
    try {
      player = VideoPlayerController.asset(StreakRenewedScreen.videoAsset);
      await player.initialize();
      if (!mounted) {
        await player.dispose();
        return;
      }
      if (!player.value.isInitialized || player.value.hasError) {
        await player.dispose();
        setState(() => _videoFailed = true);
        _timeline.forward();
        return;
      }
      await player.setLooping(false);
      player.addListener(_holdLastFrame);
      setState(() {
        _player = player;
        _videoReady = true;
      });
      _timeline.forward();
      await player.play();
    } catch (_) {
      await player?.dispose();
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _timeline.forward();
    }
  }

  void _holdLastFrame() {
    final player = _player;
    if (player == null) return;
    final duration = player.value.duration;
    if (duration <= Duration.zero) return;
    if (player.value.position >= duration - const Duration(milliseconds: 80)) {
      player.removeListener(_holdLastFrame);
      unawaited(player.pause());
    }
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _player?.removeListener(_holdLastFrame);
    unawaited(_player?.dispose() ?? Future<void>.value());
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final to = widget.toStreak;
    final chest = StreakRewardCycle.chestUnlocked(to);
    final player = _player;
    final videoReady = _videoReady &&
        player != null &&
        player.value.isInitialized &&
        player.value.size.width > 0;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFFFF6EC)),
            if (videoReady)
              Positioned.fill(
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  children: [
                    RollingStreakNumber(
                      from: widget.fromStreak,
                      to: to,
                      progress: _digits,
                    ),
                    Text(
                      'günlük seri',
                      style: AppTypography.body(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentDeep,
                      ),
                    ),
                    const Spacer(),
                    StreakCycleBar(
                      streak: to,
                      today: DateTime.now(),
                      progress: _bar,
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _motto,
                      child: Text(
                        'Harika gidiyorsun!',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _close,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          chest ? 'Ödülü Aç' : 'Devam Et',
                          style: AppTypography.body(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
