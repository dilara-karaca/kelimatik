import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/syncing_favorites_repository.dart';
import '../../data/repositories/syncing_lives_repository.dart';
import '../../data/repositories/syncing_mistakes_repository.dart';
import '../../data/repositories/syncing_stats_repository.dart';
import '../../data/repositories/syncing_streak_repository.dart';
import '../../data/services/user_local_cache.dart';
import '../../data/services/user_progress_sync_service.dart';
import '../../domain/models/daily_streak_state.dart';
import '../../features/profile/profile_model.dart';
import 'catalog_providers.dart';
import 'dependency_providers.dart';
import 'lives_provider.dart';
import 'stats_provider.dart';

/// Hydrates local cache from Supabase before the main shell opens.
///
/// Cloud is source of truth. Local is only migrated up when cloud is empty
/// and the cache belongs to the same auth user.
///
/// Also applies today's daily-streak check-in (idempotent).
Future<void> hydrateUserProgressFromCloud({
  required Ref ref,
  required Profile profile,
}) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final sync = ref.read(userProgressSyncServiceProvider);
  final uid = profile.id;

  final previousUser = prefs.getString(UserCacheKeys.lastSyncedUserId);
  if (previousUser != null && previousUser != uid) {
    await clearUserProgressLocalCache(prefs);
  }

  final statsRepo = ref.read(statsRepositoryProvider);
  final livesRepo = ref.read(livesRepositoryProvider);
  final mistakesRepo = ref.read(mistakesRepositoryProvider);
  final favoritesRepo = ref.read(favoritesRepositoryProvider);
  final streakRepo = ref.read(streakRepositoryProvider);
  final dailyRepo = ref.read(dailyStreakRepositoryProvider);

  final localStats = statsRepo.load();
  final localLives = livesRepo.load().refreshed();
  final localMistakes = mistakesRepo.loadAll();
  final localFavorites = favoritesRepo.loadIds();
  final localBest = streakRepo.loadBest();

  try {
    final cloud = await sync.pull(profile);

    final sameUserCache = previousUser == null || previousUser == uid;
    final shouldMigrate = sameUserCache &&
        cloud.stats.totalAnswered == 0 &&
        cloud.favoriteWordIds.isEmpty &&
        cloud.mistakes.isEmpty &&
        cloud.bestQuizStreak == 0 &&
        cloud.lives.isFull &&
        (localStats.totalAnswered > 0 ||
            localFavorites.isNotEmpty ||
            localMistakes.isNotEmpty ||
            localBest > 0 ||
            !localLives.isFull);

    if (shouldMigrate) {
      await sync.migrateLocalIfCloudEmpty(
        cloud: cloud,
        localStats: localStats,
        localLives: localLives,
        localBestStreak: localBest,
        localFavorites: localFavorites,
        localMistakes: localMistakes,
      );
    }

    final snapshot = shouldMigrate
        ? UserProgressSnapshot(
            stats: localStats,
            lives: localLives,
            bestQuizStreak: localBest,
            dailyStreak: DailyStreakState.evaluate(
              current: profile.dailyStreak,
              lastLoginDate: profile.lastDailyLoginDate,
            ),
            favoriteWordIds: localFavorites,
            mistakes: localMistakes,
          )
        : cloud;

    if (statsRepo is SyncingStatsRepository) {
      await statsRepo.replaceCache(snapshot.stats);
    }
    if (livesRepo is SyncingLivesRepository) {
      await livesRepo.replaceCache(snapshot.lives);
    }
    if (streakRepo is SyncingStreakRepository) {
      await streakRepo.replaceCache(snapshot.bestQuizStreak);
    }
    if (favoritesRepo is SyncingFavoritesRepository) {
      await favoritesRepo.replaceCache(snapshot.favoriteWordIds);
    }
    if (mistakesRepo is SyncingMistakesRepository) {
      await mistakesRepo.replaceCache(snapshot.mistakes);
    }

    // Daily login streak: continue / restart based on last_daily_login_date.
    await dailyRepo.checkIn(
      current: profile.dailyStreak,
      lastLoginDate: profile.lastDailyLoginDate,
    );

    await prefs.setString(UserCacheKeys.lastSyncedUserId, uid);

    ref.invalidate(statsProvider);
    ref.invalidate(livesProvider);
    ref.invalidate(bestStreakProvider);
    ref.invalidate(dailyStreakProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(mistakesProvider);
  } on UserProgressSyncFailure {
    rethrow;
  } catch (error, stack) {
    debugPrint('hydrateUserProgressFromCloud failed: $error\n$stack');
    throw const UserProgressSyncFailure(
      'İlerleme yüklenemedi. İnternetini kontrol edip tekrar dene.',
    );
  }
}
