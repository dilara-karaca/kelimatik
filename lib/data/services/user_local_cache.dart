import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/study_mode.dart';

abstract final class UserCacheKeys {
  static const lastSyncedUserId = 'last_synced_user_id';
}

/// Clears device-local quiz progress so User B never inherits User A's cache.
Future<void> clearUserProgressLocalCache(SharedPreferences prefs) async {
  await Future.wait([
    prefs.remove(FeaturePrefsKeys.mistakes),
    prefs.remove(FeaturePrefsKeys.favorites),
    prefs.remove(FeaturePrefsKeys.streakBest),
    prefs.remove(FeaturePrefsKeys.dailyStreak),
    prefs.remove(FeaturePrefsKeys.dailyStreakLastDate),
    prefs.remove(AppConstants.statsPrefsKey),
    prefs.remove(AppConstants.livesPrefsKey),
    prefs.remove(UserCacheKeys.lastSyncedUserId),
  ]);
}
