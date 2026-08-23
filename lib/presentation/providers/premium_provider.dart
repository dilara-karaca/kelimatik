import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/study_mode.dart';
import 'dependency_providers.dart';

/// Local Premium membership state (Play Billing comes later).
final premiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);

class PremiumNotifier extends Notifier<bool> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() => _prefs.getBool(FeaturePrefsKeys.premiumActive) ?? false;

  /// Stub for future billing / restore. Prefer not calling from UI yet.
  Future<void> setPremiumActive(bool value) async {
    await _prefs.setBool(FeaturePrefsKeys.premiumActive, value);
    state = value;
  }
}
