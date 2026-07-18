import '../models/quiz_stats.dart';

abstract class StatsRepository {
  QuizStats load();

  Future<void> save(QuizStats stats);
}
