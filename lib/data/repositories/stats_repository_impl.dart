import '../../domain/models/quiz_stats.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/stats_local_datasource.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl(this._dataSource);

  final StatsLocalDataSource _dataSource;

  @override
  QuizStats load() => _dataSource.load();

  @override
  Future<void> save(QuizStats stats) => _dataSource.save(stats);
}
