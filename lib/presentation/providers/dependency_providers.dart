import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/lives_local_datasource.dart';
import '../../data/datasources/stats_local_datasource.dart';
import '../../data/datasources/word_local_datasource.dart';
import '../../data/repositories/supabase_leaderboard_repository.dart';
import '../../data/repositories/syncing_daily_streak_repository.dart';
import '../../data/repositories/syncing_favorites_repository.dart';
import '../../data/repositories/syncing_lives_repository.dart';
import '../../data/repositories/syncing_mistakes_repository.dart';
import '../../data/repositories/syncing_stats_repository.dart';
import '../../data/repositories/syncing_streak_repository.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_progress_sync_service.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/lives_repository.dart';
import '../../domain/repositories/mistakes_repository.dart';
import '../../domain/repositories/stats_repository.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/repositories/word_repository.dart';

/// Overridden in [main] after SharedPreferences is ready.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProgressSyncServiceProvider = Provider<UserProgressSyncService>((ref) {
  return UserProgressSyncService();
});

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepositoryImpl(WordLocalDataSource());
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final sync = ref.watch(userProgressSyncServiceProvider);
  return SyncingStatsRepository(StatsLocalDataSource(prefs), sync);
});

final livesRepositoryProvider = Provider<LivesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final sync = ref.watch(userProgressSyncServiceProvider);
  return SyncingLivesRepository(LivesLocalDataSource(prefs), sync);
});

final mistakesRepositoryProvider = Provider<MistakesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final sync = ref.watch(userProgressSyncServiceProvider);
  return SyncingMistakesRepository(prefs, sync);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final sync = ref.watch(userProgressSyncServiceProvider);
  return SyncingFavoritesRepository(prefs, sync);
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final sync = ref.watch(userProgressSyncServiceProvider);
  return SyncingStreakRepository(prefs, sync);
});

final dailyStreakRepositoryProvider =
    Provider<SyncingDailyStreakRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final sync = ref.watch(userProgressSyncServiceProvider);
  return SyncingDailyStreakRepository(prefs, sync);
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return SupabaseLeaderboardRepository();
});
