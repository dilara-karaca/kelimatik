import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';

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
            label: 'Doğru',
            value: correctCount,
            accent: AppColors.correct,
            soft: AppColors.correctSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScoreChip(
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
    required this.label,
    required this.value,
    required this.accent,
    required this.soft,
  });

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
          Expanded(
            child: Text(
              label,
              style: AppTypography.title(color: accent, fontSize: 13),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
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
