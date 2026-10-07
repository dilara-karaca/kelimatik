import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/streak_reward_cycle.dart';
import 'app_icon.dart';

class StreakCycleBar extends StatelessWidget {
  const StreakCycleBar({
    super.key,
    required this.streak,
    required this.today,
    required this.progress,
  });

  final int streak;
  final DateTime today;
  final Animation<double> progress;

  static const int _days = StreakRewardCycle.length;
  static const double _node = 24;
  static const double _chest = 42;
  static const double _track = 5;

  @override
  Widget build(BuildContext context) {
    final filled = StreakRewardCycle.dayInCycle(streak);
    final labels = StreakRewardCycle.weekdayLabels(
      streak: streak,
      today: today,
    );
    final chest = StreakRewardCycle.chestUnlocked(streak);

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value.clamp(0.0, 1.0);
        final fillIn = ((t - 0.18) / 0.82).clamp(0.0, 1.0);
        final segments = _days - 1;
        final fillT = filled <= 1
            ? 0.0
            : ((filled - 2) + fillIn).clamp(0.0, segments.toDouble()) / segments;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: AppTypography.title(
                          fontSize: 11,
                          fontWeight: i == filled - 1
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: i < filled - 1
                              ? AppColors.accentDeep
                              : i == filled - 1
                                  ?                                       Color.lerp(
                                      AppColors.textSecondary,
                                      AppColors.accentDeep,
                                      fillIn,
                                    )!
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: _chest,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final col = constraints.maxWidth / _days;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: col / 2),
                          child: _Track(fill: fillT),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < _days; i++)
                              Expanded(
                                child: Center(
                                  child: i == _days - 1
                                      ? _ChestNode(
                                          unlocked: chest,
                                          appear: filled == _days ? fillIn : 1,
                                        )
                                      : _DayNode(
                                          filled: i < filled,
                                          appear: i < filled - 1
                                              ? 1
                                              : i == filled - 1
                                                  ? fillIn
                                                  : 0,
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: StreakCycleBar._track,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFE9E1D6),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fill.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayNode extends StatelessWidget {
  const _DayNode({
    required this.filled,
    required this.appear,
  });

  final bool filled;
  final double appear;

  @override
  Widget build(BuildContext context) {
    final t = filled ? appear.clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: StreakCycleBar._node,
      height: StreakCycleBar._node,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _EmptyDot(),
          if (t > 0)
            Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.72 + (0.28 * t),
                child: Container(
                  width: StreakCycleBar._node,
                  height: StreakCycleBar._node,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyDot extends StatelessWidget {
  const _EmptyDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: StreakCycleBar._node,
      height: StreakCycleBar._node,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD9D0C6),
          width: 1.6,
        ),
      ),
    );
  }
}

class _ChestNode extends StatelessWidget {
  const _ChestNode({
    required this.unlocked,
    required this.appear,
  });

  final bool unlocked;
  final double appear;

  @override
  Widget build(BuildContext context) {
    final t = unlocked ? appear.clamp(0.0, 1.0) : 1.0;
    return Opacity(
      opacity: unlocked ? t : 0.42,
      child: Transform.scale(
        scale: unlocked ? 0.86 + (0.14 * t) : 1,
        child: AppIcon(AppIcons.streakChest, size: StreakCycleBar._chest),
      ),
    );
  }
}
