import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';

class OutOfLivesPanel extends StatelessWidget {
  const OutOfLivesPanel({
    super.key,
    required this.nextLifeLabel,
    required this.onRestart,
  });

  final String nextLifeLabel;
  final VoidCallback onRestart;

  bool get _isReady => nextLifeLabel.isEmpty || nextLifeLabel == '00:00';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _HeartHero(),
                    const SizedBox(height: 18),
                    Text(
                      'Canların tükendi',
                      style: AppTypography.brand(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kısa bir mola verebilir veya can yenileyerek devam edebilirsin.',
                      style: AppTypography.title(fontSize: 13).copyWith(
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _RegenStatusChip(
                      isReady: _isReady,
                      countdown: nextLifeLabel,
                    ),
                    const SizedBox(height: 20),
                    _PanelButton(
                      label: 'Reklam izle · 1 can kazan',
                      icon: Icons.play_circle_filled_rounded,
                      background: AppColors.accent,
                      foreground: Colors.white,
                      onPressed: null,
                    ),
                    const SizedBox(height: 10),
                    _PanelButton(
                      label: 'Sınırsız can · Premium',
                      icon: Icons.workspace_premium_rounded,
                      background: AppColors.wrongSoft,
                      foreground: AppColors.textPrimary,
                      onPressed: null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reklam ve Premium yakında',
                      style: AppTypography.title(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRestart,
                      icon: Icon(
                        Icons.home_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      label: Text(
                        'Ana sayfaya dön',
                        style: AppTypography.body(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartHero extends StatelessWidget {
  const _HeartHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            top: 10,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.wrong.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            right: 10,
            top: 18,
            child: Icon(
              Icons.close_rounded,
              size: 12,
              color: AppColors.wrong.withValues(alpha: 0.28),
            ),
          ),
          Icon(
            Icons.favorite_rounded,
            size: 72,
            color: AppColors.wrong.withValues(alpha: 0.92),
          ),
          const Icon(
            Icons.bolt_rounded,
            size: 30,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _RegenStatusChip extends StatelessWidget {
  const _RegenStatusChip({
    required this.isReady,
    required this.countdown,
  });

  final bool isReady;
  final String countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.wrongSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          Text(
            'YENİ CANA KALAN SÜRE',
            style: AppTypography.title(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppColors.wrong,
              ),
              const SizedBox(width: 6),
              Text(
                isReady ? 'Hazır!' : countdown,
                style: AppTypography.brand(
                  color: AppColors.wrong,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: AppTypography.body(
            color: enabled ? foreground : foreground.withValues(alpha: 0.55),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.55),
          disabledForegroundColor: foreground.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
