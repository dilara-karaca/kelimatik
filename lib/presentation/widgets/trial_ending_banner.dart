import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/billing/trial_warning.dart';
import '../providers/billing_provider.dart';
import '../providers/premium_provider.dart';

/// Shown on the home screen during the last day of the yearly free trial.
class TrialEndingBanner extends ConsumerWidget {
  const TrialEndingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    final endsAt = ref.watch(yearlyTrialEndsAtProvider);
    final now = DateTime.now();
    if (!TrialWarning.showInApp(
      now: now,
      endsAt: endsAt,
      isPremium: isPremium,
    )) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TrialWarning.inAppMessage(now, endsAt!),
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(billingProvider.notifier).openSubscriptionManagement();
                  },
                  child: Text(
                    'Aboneliği yönet',
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
