import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../widgets/kelimatik_wordmark.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';

enum PremiumPlan { monthly, yearly }

/// Plan picker before Play Billing is wired.
class PremiumPlansScreen extends StatefulWidget {
  const PremiumPlansScreen({super.key});

  @override
  State<PremiumPlansScreen> createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends State<PremiumPlansScreen> {
  PremiumPlan _selected = PremiumPlan.yearly;
  bool _subscribing = false;

  Future<void> _onSubscribe() async {
    if (_subscribing) return;
    setState(() => _subscribing = true);

    // Placeholder until Google Play Billing is integrated.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() => _subscribing = false);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selected == PremiumPlan.yearly
              ? 'Yıllık plan — ödeme yakında eklenecek.'
              : 'Aylık plan — ödeme yakında eklenecek.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          const KelimatikWordmark(fontSize: 32),
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
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger,
                      child: Text(
                        'Kelimatik Premium',
                        textAlign: TextAlign.center,
                        style: AppTypography.brand(fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger * 2,
                      child: const Column(
                        children: [
                          _PerkLine(emoji: '❤️', label: 'Sınırsız can'),
                          SizedBox(height: 10),
                          _PerkLine(emoji: '🚫', label: 'Reklamsız kullanım'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger * 3,
                      child: Text(
                        'Plan seç',
                        style: AppTypography.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger * 4,
                      child: _PlanCard(
                        title: 'Yıllık',
                        price: '399,99 TL',
                        period: '/ yıl',
                        badge: '%33 tasarruf',
                        selected: _selected == PremiumPlan.yearly,
                        onTap: () =>
                            setState(() => _selected = PremiumPlan.yearly),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: AppConstants.entranceStagger * 5,
                      child: _PlanCard(
                        title: 'Aylık',
                        price: '49,99 TL',
                        period: '/ ay',
                        selected: _selected == PremiumPlan.monthly,
                        onTap: () =>
                            setState(() => _selected = PremiumPlan.monthly),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: FadeSlideIn(
                  delay: AppConstants.entranceStagger * 6,
                  child: AnimatedPressable(
                    enabled: !_subscribing,
                    onTap: _onSubscribe,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.dark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: _subscribing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Premium’a abone ol',
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

class _PerkLine extends StatelessWidget {
  const _PerkLine({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.body(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: AppTypography.body(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: price,
                          style: AppTypography.body(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' $period',
                          style: AppTypography.title(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
          width: 2,
        ),
        color: selected ? AppColors.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// Convenience push used by the Premium intro CTA.
Future<void> openPremiumPlans(BuildContext context) {
  return pushSoft(context, const PremiumPlansScreen());
}
