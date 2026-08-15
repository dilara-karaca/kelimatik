import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/study_mode.dart';
import '../../domain/repositories/streak_repository.dart';
import '../services/user_progress_sync_service.dart';

/// Local cache + Supabase `profiles.best_quiz_streak`.
class SyncingStreakRepository implements StreakRepository {
  SyncingStreakRepository(this._prefs, this._sync);

  final SharedPreferences _prefs;
  final UserProgressSyncService _sync;

  @override
  int loadBest() => _prefs.getInt(FeaturePrefsKeys.streakBest) ?? 0;

  @override
  Future<void> saveBest(int value) async {
    final previous = loadBest();
    await _prefs.setInt(FeaturePrefsKeys.streakBest, value);
    if (!_sync.hasSession) return;
    try {
      await _sync.updateProfileProgress(bestQuizStreak: value);
    } catch (_) {
      await _prefs.setInt(FeaturePrefsKeys.streakBest, previous);
      rethrow;
    }
  }

  Future<void> replaceCache(int value) =>
      _prefs.setInt(FeaturePrefsKeys.streakBest, value);
}
