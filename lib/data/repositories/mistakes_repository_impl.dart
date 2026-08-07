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

  /// Serializes read-modify-write so concurrent wrong/correct answers
  /// cannot overwrite each other via SharedPreferences.
  Future<void> _writeChain = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _writeChain.then((_) => action());
    _writeChain = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  List<MistakeEntry> loadAll() => _dataSource.load();

  @override
  Future<void> saveAll(List<MistakeEntry> entries) =>
      _enqueue(() => _dataSource.save(entries));

  @override
  Future<void> recordWrong(int wordId) {
    return _enqueue(() async {
      final entries = List<MistakeEntry>.from(loadAll());
      final index = entries.indexWhere((e) => e.wordId == wordId);
      if (index < 0) {
        entries.add(MistakeEntry.firstMiss(wordId));
      } else {
        entries[index] = entries[index].recordWrong();
      }
      await _dataSource.save(entries);
    });
  }

  @override
  Future<void> recordCorrect(int wordId) {
    return _enqueue(() async {
      final entries = List<MistakeEntry>.from(loadAll());
      final index = entries.indexWhere((e) => e.wordId == wordId);
      if (index < 0) return;
      entries[index] = entries[index].recordCorrect();
      await _dataSource.save(entries);
    });
  }
}
