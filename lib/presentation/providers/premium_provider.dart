import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/billing/billing_log.dart';
import '../../domain/models/study_mode.dart';
import 'dependency_providers.dart';

/// Local Premium membership flag used by quiz, lives, and ads.
///
/// Play Billing (via [BillingNotifier]) is the only caller of
/// [setPremiumActive]. Never set true from a button tap alone.
final premiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);

/// End of the yearly free trial, if this install recorded one.
final yearlyTrialEndsAtProvider =
    NotifierProvider<YearlyTrialNotifier, DateTime?>(YearlyTrialNotifier.new);

class PremiumNotifier extends Notifier<bool> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() => _prefs.getBool(FeaturePrefsKeys.premiumActive) ?? false;

  /// Persists Play-verified entitlement. Do not call from purchase buttons.
  Future<void> setPremiumActive(bool value) async {
    if (state != value) {
      state = value;
      billingLog(value ? 'Premium activated' : 'Premium deactivated');
      if (kDebugMode && value) {
        debugPrint('Billing: local premium flag is now true');
      }
    }
    await _prefs.setBool(FeaturePrefsKeys.premiumActive, value);
  }
}

class YearlyTrialNotifier extends Notifier<DateTime?> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  DateTime? build() {
    final raw = _prefs.getInt(FeaturePrefsKeys.premiumTrialEndsAt);
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> setEndsAt(DateTime endsAt) async {
    await _prefs.setInt(
      FeaturePrefsKeys.premiumTrialEndsAt,
      endsAt.millisecondsSinceEpoch,
    );
    state = endsAt;
  }

  Future<void> clear() async {
    await _prefs.remove(FeaturePrefsKeys.premiumTrialEndsAt);
    state = null;
  }
}
