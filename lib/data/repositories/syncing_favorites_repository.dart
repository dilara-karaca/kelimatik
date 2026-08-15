import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/study_mode.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../services/user_progress_sync_service.dart';

/// Local cache + Supabase `favorites` table.
class SyncingFavoritesRepository implements FavoritesRepository {
  SyncingFavoritesRepository(this._prefs, this._sync);

  final SharedPreferences _prefs;
  final UserProgressSyncService _sync;

  @override
  Set<int> loadIds() {
    final raw = _prefs.getStringList(FeaturePrefsKeys.favorites) ?? const [];
    return raw.map(int.parse).toSet();
  }

  @override
  bool isFavorite(int wordId) => loadIds().contains(wordId);

  @override
  Future<void> setFavorite(int wordId, bool favorite) async {
    final previous = loadIds();
    final next = Set<int>.from(previous);
    if (favorite) {
      next.add(wordId);
    } else {
      next.remove(wordId);
    }
    await _writeIds(next);
    if (!_sync.hasSession) return;
    try {
      await _sync.setFavorite(wordId, favorite);
    } catch (_) {
      await _writeIds(previous);
      rethrow;
    }
  }

  @override
  Future<void> toggle(int wordId) {
    return setFavorite(wordId, !isFavorite(wordId));
  }

  Future<void> replaceCache(Set<int> ids) => _writeIds(ids);

  Future<void> _writeIds(Set<int> ids) {
    return _prefs.setStringList(
      FeaturePrefsKeys.favorites,
      ids.map((e) => e.toString()).toList(),
    );
  }
}
