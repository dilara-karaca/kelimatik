import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/lives_state.dart';

class LivesLocalDataSource {
  LivesLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  LivesState load() {
    final raw = _prefs.getString(AppConstants.livesPrefsKey);
    if (raw == null || raw.isEmpty) return LivesState.full;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return LivesState.fromJson(map);
  }

  Future<void> save(LivesState state) {
    return _prefs.setString(
      AppConstants.livesPrefsKey,
      jsonEncode(state.toJson()),
    );
  }
}
