import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/study_mode.dart';
import '../../domain/repositories/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  int loadBest() => _prefs.getInt(FeaturePrefsKeys.streakBest) ?? 0;

  @override
  Future<void> saveBest(int value) =>
      _prefs.setInt(FeaturePrefsKeys.streakBest, value);
}
