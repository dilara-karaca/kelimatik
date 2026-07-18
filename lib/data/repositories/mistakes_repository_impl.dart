import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/mistake_entry.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/repositories/mistakes_repository.dart';

class MistakesLocalDataSource {
  MistakesLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  List<MistakeEntry> load() {
    final raw = _prefs.getString(FeaturePrefsKeys.mistakes);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(MistakeEntry.fromJson)
        .toList();
  }

  Future<void> save(List<MistakeEntry> entries) {
    return _prefs.setString(
      FeaturePrefsKeys.mistakes,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

class MistakesRepositoryImpl implements MistakesRepository {
  MistakesRepositoryImpl(this._dataSource);

  final MistakesLocalDataSource _dataSource;

  @override
  List<MistakeEntry> loadAll() => _dataSource.load();

  @override
  Future<void> saveAll(List<MistakeEntry> entries) => _dataSource.save(entries);

  @override
  Future<void> recordWrong(int wordId) async {
    final entries = loadAll();
    final index = entries.indexWhere((e) => e.wordId == wordId);
    if (index < 0) {
      entries.add(MistakeEntry.firstMiss(wordId));
    } else {
      entries[index] = entries[index].recordWrong();
    }
    await saveAll(entries);
  }

  @override
  Future<void> recordCorrect(int wordId) async {
    final entries = loadAll();
    final index = entries.indexWhere((e) => e.wordId == wordId);
    if (index < 0) return;
    entries[index] = entries[index].recordCorrect();
    await saveAll(entries);
  }
}
