import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/mistake_entry.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/repositories/mistakes_repository.dart';
import '../services/user_progress_sync_service.dart';

/// Local cache + Supabase `wrong_words` table.
class SyncingMistakesRepository implements MistakesRepository {
  SyncingMistakesRepository(this._prefs, this._sync);

  final SharedPreferences _prefs;
  final UserProgressSyncService _sync;

  Future<void> _writeChain = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _writeChain.then((_) => action());
    _writeChain = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  List<MistakeEntry> loadAll() {
    final raw = _prefs.getString(FeaturePrefsKeys.mistakes);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(MistakeEntry.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(List<MistakeEntry> entries) {
    return _enqueue(() async {
      final previous = loadAll();
      await _persist(entries);
      if (!_sync.hasSession) return;
      try {
        await _sync.replaceAllMistakes(entries);
      } catch (_) {
        await _persist(previous);
        rethrow;
      }
    });
  }

  @override
  Future<void> recordWrong(int wordId) {
    return _enqueue(() async {
      final previous = loadAll();
      final entries = List<MistakeEntry>.from(previous);
      final index = entries.indexWhere((e) => e.wordId == wordId);
      final MistakeEntry updated;
      if (index < 0) {
        updated = MistakeEntry.firstMiss(wordId);
        entries.add(updated);
      } else {
        updated = entries[index].recordWrong();
        entries[index] = updated;
      }
      await _persist(entries);
      if (!_sync.hasSession) return;
      try {
        await _sync.upsertMistake(updated);
      } catch (_) {
        await _persist(previous);
        rethrow;
      }
    });
  }

  @override
  Future<void> recordCorrect(int wordId) {
    return _enqueue(() async {
      final previous = loadAll();
      final entries = List<MistakeEntry>.from(previous);
      final index = entries.indexWhere((e) => e.wordId == wordId);
      if (index < 0) return;
      final updated = entries[index].recordCorrect();
      entries[index] = updated;
      await _persist(entries);
      if (!_sync.hasSession) return;
      try {
        await _sync.upsertMistake(updated);
      } catch (_) {
        await _persist(previous);
        rethrow;
      }
    });
  }

  Future<void> replaceCache(List<MistakeEntry> entries) => _persist(entries);

  Future<void> _persist(List<MistakeEntry> entries) {
    return _prefs.setString(
      FeaturePrefsKeys.mistakes,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
