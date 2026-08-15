import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/quiz_stats.dart';
import 'dependency_providers.dart';

final statsProvider =
    NotifierProvider<StatsNotifier, QuizStats>(StatsNotifier.new);

class StatsNotifier extends Notifier<QuizStats> {
  @override
  QuizStats build() => ref.read(statsRepositoryProvider).load();

  Future<void> recordCorrect() async {
    final previous = state;
    state = state.recordCorrect();
    try {
      await ref.read(statsRepositoryProvider).save(state);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> recordWrong() async {
    final previous = state;
    state = state.recordWrong();
    try {
      await ref.read(statsRepositoryProvider).save(state);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}
