import '../../domain/models/word_pair.dart';
import '../../domain/repositories/word_repository.dart';
import '../datasources/word_local_datasource.dart';

class WordRepositoryImpl implements WordRepository {
  WordRepositoryImpl(this._dataSource);

  final WordLocalDataSource _dataSource;
  List<WordPair>? _cache;

  @override
  Future<List<WordPair>> getAllWords() async {
    if (_cache != null) return _cache!;

    final words = await _dataSource.loadWords();
    _cache = words;
    return words;
  }
}
