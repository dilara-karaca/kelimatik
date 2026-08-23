import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/ads/rewarded_ad_service.dart';
import '../navigation/app_navigation.dart';
import '../providers/ads_provider.dart';
import '../providers/lives_provider.dart';
import 'app_icon.dart';
import 'motion/motion.dart';

enum OutOfLivesEntryResult { dismissed, lifeGained, openPremium }

/// Compact centered dialog when a mode is tapped with 0 lives.
Future<OutOfLivesEntryResult> showOutOfLivesEntryDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  ref.read(adServiceProvider).preloadFullScreenAds();

  final result = await showDialog<OutOfLivesEntryResult>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: AppColors.dark.withValues(alpha: 0.35),
    builder: (_) => const _OutOfLivesEntryDialog(),
  );
  return result ?? OutOfLivesEntryResult.dismissed;
}

class _OutOfLivesEntryDialog extends ConsumerStatefulWidget {
  const _OutOfLivesEntryDialog();

  @override
  ConsumerState<_OutOfLivesEntryDialog> createState() =>
      _OutOfLivesEntryDialogState();
}

class _OutOfLivesEntryDialogState
    extends ConsumerState<_OutOfLivesEntryDialog> {
  bool _busy = false;

  Future<void> _watchAdForLife() async {
    if (_busy) return;
    setState(() => _busy = true);

    final ads = ref.read(adServiceProvider);
    final result = await ads.showRewarded(
      onUserEarnedReward: () async {
        await ref.read(livesProvider.notifier).gainLife();
      },
    );

    if (!mounted) return;

    if (result == RewardedAdShowResult.rewarded &&
        ref.read(livesProvider).canPlay) {
      Navigator.of(context).pop(OutOfLivesEntryResult.lifeGained);
      return;
    }

    if (result == RewardedAdShowResult.unavailable) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam şu an yüklenemedi. Biraz sonra tekrar dene.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) setState(() => _busy = false);
  }

  void _goHome() {
    Navigator.of(context).pop(OutOfLivesEntryResult.dismissed);
    AppNavigation.goHomeTab(ref);
  }

  void _openPremium() {
    if (_busy) return;
    Navigator.of(context).pop(OutOfLivesEntryResult.openPremium);
  }

  @override
  Widget build(BuildContext context) {
    final lives = ref.watch(livesProvider);
    final countdown = lives.nextLifeCountdownLabel;
    final isReady = countdown.isEmpty || countdown == '00:00';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: FadeSlideIn(
        delay: Duration.zero,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.lifeGone, size: 44),
              const SizedBox(height: 12),
              Text(
                'Canın kalmadı',
                textAlign: TextAlign.center,
                style: AppTypography.brand(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(AppIcons.timer, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isReady ? 'Can hazır' : 'Yeni can · $countdown',
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: AnimatedPressable(
                  enabled: !_busy,
                  onTap: _busy ? null : _watchAdForLife,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Reklam izle +1 can',
                              style: AppTypography.body(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onTap: _busy ? null : _openPremium,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Premium ile sınırsız can',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                      decorationThickness: 1.4,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _goHome,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Ana sayfaya dön',
                  style: AppTypography.body(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
