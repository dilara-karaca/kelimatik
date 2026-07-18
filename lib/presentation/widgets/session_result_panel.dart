import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/study_mode.dart';

class SessionResultPanel extends StatelessWidget {
  const SessionResultPanel({
    super.key,
    required this.result,
    required this.onClose,
    this.onRetry,
  });

  final QuizSessionResult result;
  final VoidCallback onClose;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isStreak = result.mode == StudyMode.streak;
    final isFavorites = result.mode == StudyMode.favorites;

    final title = isStreak
        ? 'Seri Bitti!'
        : isFavorites
            ? 'Favoriler Bitti!'
            : 'Challenge Sonucu';
    final subtitle = isStreak
        ? 'İlk yanlışta seri sona erdi'
        : isFavorites
            ? 'Tüm favori kelimeleri tamamladın'
            : 'Tur tamamlandı';
    final icon = isStreak
        ? Icons.local_fire_department_outlined
        : isFavorites
            ? Icons.star_rounded
            : Icons.emoji_events_outlined;
    final accent = isStreak
        ? AppColors.accent
        : isFavorites
            ? AppColors.accent
            : AppColors.sky;

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: AppTypography.brand(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTypography.title(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (isStreak) ...[
                    _MiniStat(
                      label: 'Yaptığın seri',
                      value: '${result.currentStreak}',
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 8),
                    _MiniStat(
                      label: 'En yüksek seri',
                      value: '${result.bestStreak}',
                      color: AppColors.mint,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Doğru',
                            value: '${result.correct}',
                            color: AppColors.correct,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniStat(
                            label: 'Yanlış',
                            value: '${result.wrong}',
                            color: AppColors.wrong,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MiniStat(
                      label: 'Başarı',
                      value: '%${result.successRate.round()}',
                      color: AppColors.sky,
                    ),
                    if (!isFavorites) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Süre',
                              value: result.elapsedLabel,
                              color: AppColors.accentDeep,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                              label: 'Kelime',
                              value: '${result.answered}',
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  if (onRetry != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Tekrar Çalış',
                          style: AppTypography.body(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: onClose,
                        child: Text(
                          'Tamam',
                          style: AppTypography.body(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: onClose,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Tamam',
                          style: AppTypography.body(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.title(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.score(color: color, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
