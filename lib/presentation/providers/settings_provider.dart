import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/quiz_haptics.dart';
import '../../domain/models/study_mode.dart';
import 'dependency_providers.dart';

class AppSettingsState {
  const AppSettingsState({
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
  });

  final bool hapticsEnabled;
  final bool notificationsEnabled;

  AppSettingsState copyWith({
    bool? hapticsEnabled,
    bool? notificationsEnabled,
  }) {
    return AppSettingsState(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettingsState build() {
    final haptics =
        _prefs.getBool(FeaturePrefsKeys.hapticsEnabled) ?? true;
    final notifications =
        _prefs.getBool(FeaturePrefsKeys.notificationsEnabled) ?? true;
    QuizHaptics.enabled = haptics;
    return AppSettingsState(
      hapticsEnabled: haptics,
      notificationsEnabled: notifications,
    );
  }

  Future<void> setHapticsEnabled(bool value) async {
    await _prefs.setBool(FeaturePrefsKeys.hapticsEnabled, value);
    QuizHaptics.enabled = value;
    state = state.copyWith(hapticsEnabled: value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(FeaturePrefsKeys.notificationsEnabled, value);
    state = state.copyWith(notificationsEnabled: value);
  }
}
