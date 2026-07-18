import '../../domain/models/lives_state.dart';
import '../../domain/repositories/lives_repository.dart';
import '../datasources/lives_local_datasource.dart';

class LivesRepositoryImpl implements LivesRepository {
  LivesRepositoryImpl(this._dataSource);

  final LivesLocalDataSource _dataSource;

  @override
  LivesState load() => _dataSource.load();

  @override
  Future<void> save(LivesState state) => _dataSource.save(state);
}
