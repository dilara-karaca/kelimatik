import 'dart:async';

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
    await _local.save(state);
    if (!_sync.hasSession) return;
    unawaited(_pushCloud(state));
  }

  Future<void> _pushCloud(LivesState state) async {
    try {
      await _sync.updateProfileProgress(lives: state);
    } catch (_) {}
  }

  Future<void> replaceCache(LivesState state) => _local.save(state);
}
