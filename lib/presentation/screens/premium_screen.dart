import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../navigation/app_navigation.dart';
import '../providers/premium_provider.dart';
import '../widgets/app_icon.dart';
import '../widgets/kelimatik_wordmark.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';
import 'premium_plans_screen.dart';

/// Premium details / purchase entry (billing not wired yet).
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => AppNavigation.popRoute(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                  children: [
                    FadeSlideIn(
                      delay: Duration.zero,
                      child: Column(
                        children: [
                          const KelimatikWordmark(fontSize: 36),
                          const SizedBox(height: 6),
                          Text(
                            'PREMIUM',
                            style: AppTypography.title(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ).copyWith(letterSpacing: 3.2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger,
                      child: Text(
                        isPremium
                            ? 'Üyeliğin aktif. Sınırsız can ve\nreklamsız oyun seninle.'
                            : 'Sınırsız can.\nReklamsız oyun.',
                        textAlign: TextAlign.center,
                        style: AppTypography.brand(fontSize: 28).copyWith(
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger * 2,
                      child: Text(
                        isPremium
                            ? 'İstediğin zaman aboneliğini buradan yönetebilirsin.'
                            : 'Kesintisiz pratik için tek adım.',
                        textAlign: TextAlign.center,
                        style: AppTypography.title(fontSize: 14).copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger * 3,
                      child: const _BenefitBlock(
                        assetIcon: AppIcons.lifeFull,
                        title: 'Sınırsız can',
                        body: 'Can beklemeden istediğin kadar oyna.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Divider(
                        height: 1,
                        color: AppColors.divider.withValues(alpha: 0.9),
                      ),
                    ),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger * 4,
                      child: const _BenefitBlock(
                        materialIcon: Icons.visibility_off_outlined,
                        title: 'Reklamsız kullanım',
                        body:
                            'Banner ve ödüllü reklamlar olmadan kesintisiz deneyim.',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: FadeSlideIn(
                  delay: AppConstants.entranceStagger * 5,
                  child: AnimatedPressable(
                    onTap: () {
                      if (isPremium) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Abonelik yönetimi yakında eklenecek.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      openPremiumPlans(context);
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.dark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text(
                            isPremium ? 'Aboneliği yönet' : 'Premium’a geç',
                            style: AppTypography.body(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _BenefitBlock extends StatelessWidget {
  const _BenefitBlock({
    required this.title,
    required this.body,
    this.assetIcon,
    this.materialIcon,
  }) : assert(assetIcon != null || materialIcon != null);

  final String? assetIcon;
  final IconData? materialIcon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: materialIcon != null
              ? Icon(materialIcon, color: AppColors.primary, size: 28)
              : AppIcon(assetIcon!, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.brand(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppTypography.title(fontSize: 13).copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
