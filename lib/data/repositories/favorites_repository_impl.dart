import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/study_mode.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Set<int> loadIds() {
    final raw = _prefs.getStringList(FeaturePrefsKeys.favorites) ?? const [];
    return raw.map(int.parse).toSet();
  }

  @override
  bool isFavorite(int wordId) => loadIds().contains(wordId);

  @override
  Future<void> setFavorite(int wordId, bool favorite) async {
    final ids = loadIds();
    if (favorite) {
      ids.add(wordId);
    } else {
      ids.remove(wordId);
    }
    await _prefs.setStringList(
      FeaturePrefsKeys.favorites,
      ids.map((e) => e.toString()).toList(),
    );
  }

  @override
  Future<void> toggle(int wordId) {
    return setFavorite(wordId, !isFavorite(wordId));
  }
}
