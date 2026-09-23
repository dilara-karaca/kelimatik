import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/quiz_stats.dart';
import 'dependency_providers.dart';

final statsProvider =
    NotifierProvider<StatsNotifier, QuizStats>(StatsNotifier.new);

class StatsNotifier extends Notifier<QuizStats> {
  @override
  QuizStats build() => ref.read(statsRepositoryProvider).load();

  Future<void> recordCorrect() async {
    state = state.recordCorrect();
    try {
      await ref.read(statsRepositoryProvider).save(state);
    } catch (_) {}
  }

  Future<void> recordWrong() async {
    state = state.recordWrong();
    try {
      await ref.read(statsRepositoryProvider).save(state);
    } catch (_) {}
  }
}
