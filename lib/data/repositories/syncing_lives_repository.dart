import '../../domain/models/lives_state.dart';
import '../../domain/repositories/lives_repository.dart';
import '../datasources/lives_local_datasource.dart';
import '../services/user_progress_sync_service.dart';

/// Local cache + Supabase `profiles.lives_*`.
class SyncingLivesRepository implements LivesRepository {
  SyncingLivesRepository(this._local, this._sync);

  final LivesLocalDataSource _local;
  final UserProgressSyncService _sync;

  @override
  LivesState load() => _local.load();

  @override
  Future<void> save(LivesState state) async {
    final previous = _local.load();
    await _local.save(state);
    if (!_sync.hasSession) return;
    try {
      await _sync.updateProfileProgress(lives: state);
    } catch (_) {
      await _local.save(previous);
      rethrow;
    }
  }

  Future<void> replaceCache(LivesState state) => _local.save(state);
}
