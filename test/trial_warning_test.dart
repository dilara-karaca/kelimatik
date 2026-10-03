import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/data/services/billing/trial_warning.dart';

void main() {
  test('in-app warning is only the last day of an active trial', () {
    final endsAt = DateTime(2026, 8, 26, 15);

    expect(
      TrialWarning.showInApp(
        now: DateTime(2026, 8, 25, 14),
        endsAt: endsAt,
        isPremium: true,
      ),
      isFalse,
    );
    expect(
      TrialWarning.showInApp(
        now: DateTime(2026, 8, 25, 15),
        endsAt: endsAt,
        isPremium: true,
      ),
      isTrue,
    );
    expect(
      TrialWarning.showInApp(
        now: DateTime(2026, 8, 26, 15),
        endsAt: endsAt,
        isPremium: true,
      ),
      isFalse,
    );
    expect(
      TrialWarning.showInApp(
        now: DateTime(2026, 8, 25, 16),
        endsAt: endsAt,
        isPremium: false,
      ),
      isFalse,
    );
  });

  test('copy says today when the trial ends the same day', () {
    final endsAt = DateTime(2026, 8, 26, 18);
    expect(
      TrialWarning.inAppMessage(DateTime(2026, 8, 25, 18), endsAt),
      contains('yarın'),
    );
    expect(
      TrialWarning.inAppMessage(DateTime(2026, 8, 26, 9), endsAt),
      contains('bugün'),
    );
  });
}
