import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import 'app_icon.dart';
import 'motion/motion.dart';

class OutOfLivesPanel extends StatelessWidget {
  const OutOfLivesPanel({
    super.key,
    required this.nextLifeLabel,
    required this.onRestart,
    this.onWatchAd,
    this.watchAdEnabled = true,
  });

  final String nextLifeLabel;
  final VoidCallback onRestart;

  /// When non-null, enables "Reklam izle · 1 can kazan".
  final VoidCallback? onWatchAd;

  /// Disable while an ad is loading/showing (no spam taps).
  final bool watchAdEnabled;

  bool get _isReady => nextLifeLabel.isEmpty || nextLifeLabel == '00:00';

  @override
  Widget build(BuildContext context) {
    return SoftOverlayAppear(
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
                const AppIcon(AppIcons.lifeGone, size: 72),
                const SizedBox(height: 18),
                Text(
                  'Canların Tükendi',
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
                  onPressed: (onWatchAd != null && watchAdEnabled)
                      ? onWatchAd
                      : null,
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
                AnimatedPressable(
                  child: TextButton.icon(
                    onPressed: onRestart,
                    icon: const AppIcon(AppIcons.home, size: 18),
                    label: Text(
                      'Ana sayfaya dön',
                      style: AppTypography.body(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              const AppIcon(AppIcons.timer, size: 18),
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
      child: AnimatedPressable(
        enabled: enabled,
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
      ),
    );
  }
}
