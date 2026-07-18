import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/mistake_entry.dart';
import '../../domain/models/word_pair.dart';
import 'dependency_providers.dart';

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
    await ref.read(favoritesRepositoryProvider).toggle(wordId);
    state = ref.read(favoritesRepositoryProvider).loadIds();
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
    await ref.read(streakRepositoryProvider).saveBest(streak);
    state = streak;
  }
}

final leaderboardProvider = FutureProvider((ref) {
  return ref.watch(leaderboardRepositoryProvider).fetchTop();
});
