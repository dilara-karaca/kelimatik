import '../models/mistake_entry.dart';

abstract class MistakesRepository {
  List<MistakeEntry> loadAll();

  Future<void> recordWrong(int wordId);

  Future<void> recordCorrect(int wordId);

  Future<void> saveAll(List<MistakeEntry> entries);
}
