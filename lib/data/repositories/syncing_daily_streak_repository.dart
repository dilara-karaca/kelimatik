import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/daily_streak_state.dart';
import '../../domain/models/study_mode.dart';
import '../services/user_progress_sync_service.dart';

/// Local cache + Supabase `profiles.daily_streak` / `last_daily_login_date`.
class SyncingDailyStreakRepository {
  SyncingDailyStreakRepository(this._prefs, this._sync);

  final SharedPreferences _prefs;
  final UserProgressSyncService _sync;

  DailyStreakState load() {
    final current = _prefs.getInt(FeaturePrefsKeys.dailyStreak) ?? 0;
    final lastRaw = _prefs.getString(FeaturePrefsKeys.dailyStreakLastDate);
    final last = DailyStreakState.parseDate(lastRaw);
    return DailyStreakState.evaluate(
      current: current,
      lastLoginDate: last,
    );
  }

  Future<void> replaceCache(DailyStreakState state) async {
    await _prefs.setInt(FeaturePrefsKeys.dailyStreak, state.current);
    final last = state.lastLoginDate;
    if (last == null) {
      await _prefs.remove(FeaturePrefsKeys.dailyStreakLastDate);
    } else {
      await _prefs.setString(
        FeaturePrefsKeys.dailyStreakLastDate,
        DailyStreakState.formatDate(last),
      );
    }
  }

  /// Writes today's check-in to cache + Supabase. Idempotent same day.
  Future<DailyStreakState> checkIn({
    required int current,
    required DateTime? lastLoginDate,
    DateTime? now,
  }) async {
    final next = DailyStreakState.checkIn(
      current: current,
      lastLoginDate: lastLoginDate,
      now: now,
    );
    final previous = load();
    await replaceCache(next);
    if (!_sync.hasSession) return next;
    try {
      await _sync.updateDailyStreak(next);
    } catch (_) {
      await replaceCache(previous);
      rethrow;
    }
    return next;
  }
}
