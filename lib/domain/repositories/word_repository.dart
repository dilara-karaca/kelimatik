import '../models/word_pair.dart';

abstract class WordRepository {
  Future<List<WordPair>> getAllWords();
}
