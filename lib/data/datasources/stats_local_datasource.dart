import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/quiz_stats.dart';

/// Persists quiz statistics via SharedPreferences.
class StatsLocalDataSource {
  StatsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  QuizStats load() {
    final raw = _prefs.getString(AppConstants.statsPrefsKey);
    if (raw == null || raw.isEmpty) return QuizStats.empty;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return QuizStats.fromJson(map);
  }

  Future<void> save(QuizStats stats) {
    return _prefs.setString(
      AppConstants.statsPrefsKey,
      jsonEncode(stats.toJson()),
    );
  }
}
