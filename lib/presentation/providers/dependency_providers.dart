import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/lives_local_datasource.dart';
import '../../data/datasources/stats_local_datasource.dart';
import '../../data/datasources/word_local_datasource.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/repositories/lives_repository_impl.dart';
import '../../data/repositories/mistakes_repository_impl.dart';
import '../../data/repositories/mock_leaderboard_repository.dart';
import '../../data/repositories/stats_repository_impl.dart';
import '../../data/repositories/streak_repository_impl.dart';
import '../../data/repositories/word_repository_impl.dart';
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

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepositoryImpl(WordLocalDataSource());
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StatsRepositoryImpl(StatsLocalDataSource(prefs));
});

final livesRepositoryProvider = Provider<LivesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LivesRepositoryImpl(LivesLocalDataSource(prefs));
});

final mistakesRepositoryProvider = Provider<MistakesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MistakesRepositoryImpl(MistakesLocalDataSource(prefs));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesRepositoryImpl(prefs);
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StreakRepositoryImpl(prefs);
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return MockLeaderboardRepository();
});
