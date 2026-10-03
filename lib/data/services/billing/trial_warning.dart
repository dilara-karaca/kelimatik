import '../../../core/config/billing_config.dart';

/// When to warn that the yearly free trial is about to become a paid renewal.
abstract final class TrialWarning {
  static DateTime endsAtFromStart(DateTime startedAt) =>
      startedAt.add(BillingConfig.yearlyFreeTrial);

  static DateTime? notificationAt(DateTime? endsAt) {
    if (endsAt == null) return null;
    return endsAt.subtract(BillingConfig.trialWarningLead);
  }

  /// True from 24 hours before the trial ends until the trial ends.
  static bool showInApp({
    required DateTime now,
    required DateTime? endsAt,
    required bool isPremium,
  }) {
    if (!isPremium || endsAt == null) return false;
    final warnAt = endsAt.subtract(BillingConfig.trialWarningLead);
    return !now.isBefore(warnAt) && now.isBefore(endsAt);
  }

  static String inAppMessage(DateTime now, DateTime endsAt) {
    final sameDay = now.year == endsAt.year &&
        now.month == endsAt.month &&
        now.day == endsAt.day;
    if (sameDay) {
      return 'Ücretsiz denemen bugün bitiyor. İptal etmezsen yıllık ücretin alınır.';
    }
    return 'Ücretsiz denemen yarın bitiyor. İptal etmezsen yıllık ücretin alınır.';
  }
}
