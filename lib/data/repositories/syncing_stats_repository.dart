import '../../domain/models/quiz_stats.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/stats_local_datasource.dart';
import '../services/user_progress_sync_service.dart';

/// Local cache + Supabase `profiles.correct_count` / `wrong_count`.
class SyncingStatsRepository implements StatsRepository {
  SyncingStatsRepository(this._local, this._sync);

  final StatsLocalDataSource _local;
  final UserProgressSyncService _sync;

  @override
  QuizStats load() => _local.load();

  @override
  Future<void> save(QuizStats stats) async {
    final previous = _local.load();
    await _local.save(stats);
    if (!_sync.hasSession) return;
    try {
      await _sync.updateProfileProgress(stats: stats);
    } catch (_) {
      await _local.save(previous);
      rethrow;
    }
  }

  Future<void> replaceCache(QuizStats stats) => _local.save(stats);
}
