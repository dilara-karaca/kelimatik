import 'dart:async';

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
    await _local.save(stats);
    if (!_sync.hasSession) return;
    unawaited(_pushCloud(stats));
  }

  Future<void> _pushCloud(QuizStats stats) async {
    try {
      await _sync.updateProfileProgress(stats: stats);
    } catch (_) {}
  }

  Future<void> replaceCache(QuizStats stats) => _local.save(stats);
}
