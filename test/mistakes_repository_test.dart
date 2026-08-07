import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kelimatik/data/repositories/mistakes_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MistakesRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = MistakesRepositoryImpl(MistakesLocalDataSource(prefs));
  });

  test('recordWrong persists word for mistakes mode pool', () async {
    await repo.recordWrong(5);
    final ids = repo.loadAll().map((e) => e.wordId).toSet();
    expect(ids, contains(5));
  });

  test('concurrent wrong answers do not drop entries', () async {
    await Future.wait([
      repo.recordWrong(1),
      repo.recordWrong(2),
      repo.recordWrong(3),
    ]);
    final ids = repo.loadAll().map((e) => e.wordId).toSet();
    expect(ids, {1, 2, 3});
  });

  test('recordCorrect keeps the mistake entry', () async {
    await repo.recordWrong(9);
    await repo.recordCorrect(9);
    final entry = repo.loadAll().singleWhere((e) => e.wordId == 9);
    expect(entry.wrongCount, 1);
    expect(entry.correctSinceMissCount, 1);
  });
}
