import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import 'lives_hearts.dart';

class OutOfLivesPanel extends StatelessWidget {
  const OutOfLivesPanel({
    super.key,
    required this.nextLifeLabel,
    required this.onRestart,
  });

  final String nextLifeLabel;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.wrongSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.wrong,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Canların bitti!',
                    style: AppTypography.brand(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextLifeLabel.isEmpty
                        ? 'Biraz dinlen, sonra tekrar dene.'
                        : 'Sonraki can: $nextLifeLabel',
                    style: AppTypography.title(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const LivesHearts(current: 0, size: 28, spacing: 6),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: onRestart,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Tekrar Başla',
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
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.ondemand_video_outlined),
                      label: Text(
                        'Can Kazan',
                        style: AppTypography.body(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sky,
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.sky.withValues(alpha: 0.35),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video ile can kazanma yakında',
                    style: AppTypography.title(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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
