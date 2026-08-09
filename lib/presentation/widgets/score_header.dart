import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import 'app_icon.dart';
import 'motion/motion.dart';

class ScoreHeader extends StatelessWidget {
  const ScoreHeader({
    super.key,
    required this.correctCount,
    required this.wrongCount,
  });

  final int correctCount;
  final int wrongCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScoreChip(
            icon: AppIcons.correct,
            label: 'Doğru',
            value: correctCount,
            accent: AppColors.correct,
            soft: AppColors.correctSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScoreChip(
            icon: AppIcons.wrong,
            label: 'Yanlış',
            value: wrongCount,
            accent: AppColors.wrong,
            soft: AppColors.wrongSoft,
          ),
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.soft,
  });

  final String icon;
  final String label;
  final int value;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.title(color: accent, fontSize: 13),
            ),
          ),
          AnimatedSwitcher(
            duration: AppConstants.cardSwap,
            switchInCurve: AppConstants.pageCurve,
            switchOutCurve: AppConstants.pageReverseCurve,
            transitionBuilder: softFadeSlideTransition,
            child: Text(
              '$value',
              key: ValueKey(value),
              style: AppTypography.score(color: accent, fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}
