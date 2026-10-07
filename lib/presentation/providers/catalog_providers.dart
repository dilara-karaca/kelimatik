import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/daily_streak_goal.dart';
import '../../domain/models/daily_streak_state.dart';
import '../../domain/models/mistake_entry.dart';
import '../../domain/models/streak_reward_cycle.dart';
import '../../domain/models/word_pair.dart';
import 'dependency_providers.dart';
import 'notification_provider.dart';

final wordsListProvider = FutureProvider<List<WordPair>>((ref) {
  return ref.watch(wordRepositoryProvider).getAllWords();
});

final wordByIdProvider = Provider.family<WordPair?, int>((ref, id) {
  final async = ref.watch(wordsListProvider);
  return async.maybeWhen(
    data: (words) {
      for (final w in words) {
        if (w.id == id) return w;
      }
      return null;
    },
    orElse: () => null,
  );
});

final wordOfTheDayProvider = Provider<WordPair?>((ref) {
  final async = ref.watch(wordsListProvider);
  return async.maybeWhen(
    data: (words) {
      if (words.isEmpty) return null;
      final day = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
      return words[day % words.length];
    },
    orElse: () => null,
  );
});

final mistakesProvider =
    NotifierProvider<MistakesNotifier, List<MistakeEntry>>(MistakesNotifier.new);

class MistakesNotifier extends Notifier<List<MistakeEntry>> {
  @override
  List<MistakeEntry> build() =>
      ref.read(mistakesRepositoryProvider).loadAll();

  Future<void> recordWrong(int wordId) async {
    await ref.read(mistakesRepositoryProvider).recordWrong(wordId);
    state = ref.read(mistakesRepositoryProvider).loadAll();
  }

  Future<void> recordCorrect(int wordId) async {
    await ref.read(mistakesRepositoryProvider).recordCorrect(wordId);
    state = ref.read(mistakesRepositoryProvider).loadAll();
  }

  void reload() {
    state = ref.read(mistakesRepositoryProvider).loadAll();
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.read(favoritesRepositoryProvider).loadIds();

  Future<void> toggle(int wordId) async {
    final previous = state;
    final next = Set<int>.from(previous);
    if (next.contains(wordId)) {
      next.remove(wordId);
    } else {
      next.add(wordId);
    }
    state = next;
    try {
      await ref.read(favoritesRepositoryProvider).setFavorite(
            wordId,
            next.contains(wordId),
          );
      state = ref.read(favoritesRepositoryProvider).loadIds();
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  bool isFavorite(int wordId) => state.contains(wordId);
}

final bestStreakProvider =
    NotifierProvider<BestStreakNotifier, int>(BestStreakNotifier.new);

class BestStreakNotifier extends Notifier<int> {
  @override
  int build() => ref.read(streakRepositoryProvider).loadBest();

  Future<void> consider(int streak) async {
    if (streak <= state) return;
    final previous = state;
    state = streak;
    try {
      await ref.read(streakRepositoryProvider).saveBest(streak);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final dailyStreakProvider =
    NotifierProvider<DailyStreakNotifier, DailyStreakState>(
  DailyStreakNotifier.new,
);

class DailyStreakNotifier extends Notifier<DailyStreakState> {
  Future<void> _inFlightPlay = Future<void>.value();

  @override
  DailyStreakState build() => ref.read(dailyStreakRepositoryProvider).load();

  void reload() {
    state = ref.read(dailyStreakRepositoryProvider).load();
  }

  /// One-shot event for the celebration screen. Null after it is consumed.
  Future<StreakRenewalEvent?> takePendingCelebration() {
    return ref.read(dailyStreakRepositoryProvider).takePendingCelebration();
  }

  Future<void> waitForInFlightPlay() async {
    await _inFlightPlay;
    await ref.read(dailyStreakRepositoryProvider).waitForIdle();
  }

  /// Counts one quiz answer toward today's goal. Check-in runs at 10 answers.
  Future<void> recordPlay({DateTime? now}) {
    final run = _recordPlay(now: now);
    _inFlightPlay = run.catchError((_) {});
    return run;
  }

  Future<void> _recordPlay({DateTime? now}) async {
    final result =
        await ref.read(dailyStreakRepositoryProvider).recordPlay(now: now);
    state = result.streak;
    ref.invalidate(dailyStreakGoalProvider);
    if (!result.didCheckIn) return;
    unawaited(
      ref
          .read(notificationCoordinatorProvider)
          .recordStreakActivity(now ?? DateTime.now()),
    );
  }

  /// If the 10-word goal is already done but check-in was skipped, apply it.
  Future<void> syncCompletedGoal({DateTime? now}) async {
    final result = await ref
        .read(dailyStreakRepositoryProvider)
        .applyCompletedGoalCheckIn(now: now);
    if (!result.didCheckIn) return;
    state = result.streak;
    unawaited(
      ref
          .read(notificationCoordinatorProvider)
          .recordStreakActivity(now ?? DateTime.now()),
    );
  }
}

final dailyStreakGoalProvider =
    NotifierProvider<DailyStreakGoalNotifier, DailyStreakGoal>(
  DailyStreakGoalNotifier.new,
);

class DailyStreakGoalNotifier extends Notifier<DailyStreakGoal> {
  @override
  DailyStreakGoal build() =>
      ref.read(dailyStreakRepositoryProvider).loadGoal();

  void reload() {
    state = ref.read(dailyStreakRepositoryProvider).loadGoal();
  }
}

final leaderboardProvider = FutureProvider((ref) {
  return ref.watch(leaderboardRepositoryProvider).fetchTop(limit: 500);
});
