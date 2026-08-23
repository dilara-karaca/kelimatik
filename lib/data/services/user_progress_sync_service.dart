import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/daily_streak_state.dart';
import '../../domain/models/lives_state.dart';
import '../../domain/models/mistake_entry.dart';
import '../../domain/models/quiz_stats.dart';
import '../../features/profile/profile_model.dart';

/// Failure while reading/writing user progress on Supabase.
class UserProgressSyncFailure implements Exception {
  const UserProgressSyncFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Snapshot of progress fields pulled from Supabase.
class UserProgressSnapshot {
  const UserProgressSnapshot({
    required this.stats,
    required this.lives,
    required this.bestQuizStreak,
    required this.dailyStreak,
    required this.favoriteWordIds,
    required this.mistakes,
  });

  final QuizStats stats;
  final LivesState lives;
  final int bestQuizStreak;
  final DailyStreakState dailyStreak;
  final Set<int> favoriteWordIds;
  final List<MistakeEntry> mistakes;
}

/// Supabase source-of-truth for quiz progress, favorites, and mistakes.
class UserProgressSyncService {
  UserProgressSyncService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get _user => _client.auth.currentUser;

  bool get hasSession => _user != null;

  String get _uid {
    final user = _user;
    if (user == null) {
      throw const UserProgressSyncFailure(
        'Oturum bulunamadı. Tekrar giriş yap.',
      );
    }
    return user.id;
  }

  Future<UserProgressSnapshot> pull(Profile profile) async {
    final uid = _uid;

    try {
      final favRows = await _client
          .from('favorites')
          .select('word_id')
          .eq('user_id', uid);

      final wrongRows =
          await _client.from('wrong_words').select().eq('user_id', uid);

      final favorites = <int>{
        for (final row in favRows as List<dynamic>)
          ((row as Map<String, dynamic>)['word_id'] as num).toInt(),
      };

      final mistakes = (wrongRows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mistakeFromRow)
          .toList()
        ..sort((a, b) => b.lastMissedAt.compareTo(a.lastMissedAt));

      final livesCurrent = (profile.livesCurrent ?? AppConstants.maxLives)
          .clamp(0, AppConstants.maxLives)
          .toInt();
      final lives = LivesState(
        current: livesCurrent,
        regenStartedAt: profile.livesRegenStartedAt,
      ).refreshed();

      return UserProgressSnapshot(
        stats: QuizStats(
          totalCorrect: profile.correctCount,
          totalWrong: profile.wrongCount,
        ),
        lives: lives,
        bestQuizStreak: profile.bestQuizStreak,
        dailyStreak: DailyStreakState.evaluate(
          current: profile.dailyStreak,
          lastLoginDate: profile.lastDailyLoginDate,
        ),
        favoriteWordIds: favorites,
        mistakes: mistakes,
      );
    } on UserProgressSyncFailure {
      rethrow;
    } on PostgrestException catch (error, stack) {
      debugPrint('UserProgressSyncService.pull failed: $error\n$stack');
      throw UserProgressSyncFailure(_mapPostgrest(error));
    } catch (error, stack) {
      debugPrint('UserProgressSyncService.pull failed: $error\n$stack');
      throw const UserProgressSyncFailure(
        'İlerleme yüklenemedi. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  /// Upload local cache once when cloud has no meaningful progress yet.
  Future<void> migrateLocalIfCloudEmpty({
    required UserProgressSnapshot cloud,
    required QuizStats localStats,
    required LivesState localLives,
    required int localBestStreak,
    required Set<int> localFavorites,
    required List<MistakeEntry> localMistakes,
  }) async {
    final cloudEmpty = cloud.stats.totalAnswered == 0 &&
        cloud.favoriteWordIds.isEmpty &&
        cloud.mistakes.isEmpty &&
        cloud.bestQuizStreak == 0 &&
        cloud.lives.isFull;

    final localHasData = localStats.totalAnswered > 0 ||
        localFavorites.isNotEmpty ||
        localMistakes.isNotEmpty ||
        localBestStreak > 0 ||
        !localLives.isFull;

    if (!cloudEmpty || !localHasData) return;

    await updateProfileProgress(
      stats: localStats,
      lives: localLives,
      bestQuizStreak: localBestStreak,
    );
    await replaceAllFavorites(localFavorites);
    await replaceAllMistakes(localMistakes);
  }

  Future<void> updateProfileProgress({
    QuizStats? stats,
    LivesState? lives,
    int? bestQuizStreak,
  }) async {
    final uid = _uid;
    final payload = <String, dynamic>{
      'last_played_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (stats != null) {
      payload['correct_count'] = stats.totalCorrect;
      payload['wrong_count'] = stats.totalWrong;
      // XP = correct answers × xpPerCorrectAnswer (wrong answers add 0).
      payload['xp'] = stats.xp;
      payload['level'] = (1 + (stats.totalCorrect ~/ 25)).clamp(1, 99);
    }
    if (bestQuizStreak != null) {
      payload['best_quiz_streak'] = bestQuizStreak;
    }
    if (lives != null) {
      payload['lives_current'] =
          lives.current.clamp(0, AppConstants.maxLives).toInt();
      payload['lives_regen_started_at'] =
          lives.regenStartedAt?.toUtc().toIso8601String();
    }

    try {
      await _client.from('profiles').update(payload).eq('id', uid);
    } on PostgrestException catch (error, stack) {
      debugPrint('updateProfileProgress failed: $error\n$stack');
      throw UserProgressSyncFailure(_mapPostgrest(error));
    } catch (error, stack) {
      debugPrint('updateProfileProgress failed: $error\n$stack');
      throw const UserProgressSyncFailure(
        'İlerleme kaydedilemedi. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  Future<void> updateDailyStreak(DailyStreakState streak) async {
    final uid = _uid;
    try {
      await _client.from('profiles').update({
        'daily_streak': streak.current,
        'last_daily_login_date': streak.lastLoginDate == null
            ? null
            : DailyStreakState.formatDate(streak.lastLoginDate!),
        // Keep legacy column aligned for older reads.
        'streak': streak.current,
      }).eq('id', uid);
    } on PostgrestException catch (error, stack) {
      debugPrint('updateDailyStreak failed: $error\n$stack');
      throw UserProgressSyncFailure(_mapPostgrest(error));
    } catch (error, stack) {
      debugPrint('updateDailyStreak failed: $error\n$stack');
      throw const UserProgressSyncFailure(
        'Günlük seri kaydedilemedi. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  Future<void> setFavorite(int wordId, bool favorite) async {
    final uid = _uid;
    try {
      if (favorite) {
        await _client.from('favorites').upsert(
          {
            'user_id': uid,
            'word_id': wordId,
          },
          onConflict: 'user_id,word_id',
        );
      } else {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', uid)
            .eq('word_id', wordId);
      }
    } on PostgrestException catch (error, stack) {
      debugPrint('setFavorite failed: $error\n$stack');
      throw UserProgressSyncFailure(_mapPostgrest(error));
    } catch (error, stack) {
      debugPrint('setFavorite failed: $error\n$stack');
      throw const UserProgressSyncFailure(
        'Favori kaydedilemedi. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  Future<void> replaceAllFavorites(Set<int> wordIds) async {
    final uid = _uid;
    try {
      await _client.from('favorites').delete().eq('user_id', uid);
      if (wordIds.isEmpty) return;
      await _client.from('favorites').insert([
        for (final id in wordIds) {'user_id': uid, 'word_id': id},
      ]);
    } on PostgrestException catch (error, stack) {
      debugPrint('replaceAllFavorites failed: $error\n$stack');
      throw UserProgressSyncFailure(_mapPostgrest(error));
    } catch (error, stack) {
      debugPrint('replaceAllFavorites failed: $error\n$stack');
      throw const UserProgressSyncFailure(
        'Favoriler senkronlanamadı. Lütfen tekrar dene.',
      );
    }
  }

  Future<void> upsertMistake(MistakeEntry entry) async {
    final uid = _uid;
    try {
      await _client.from('wrong_words').upsert(
        _mistakeToRow(uid, entry),
        onConflict: 'user_id,word_id',
      );
    } on PostgrestException catch (error, stack) {
      debugPrint('upsertMistake failed: $error\n$stack');
      throw UserProgressSyncFailure(_mapPostgrest(error));
    } catch (error, stack) {
      debugPrint('upsertMistake failed: $error\n$stack');
      throw const UserProgressSyncFailure(
        'Yanlış kelime kaydedilemedi. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  Future<void> replaceAllMistakes(List<MistakeEntry> entries) async {
    final uid = _uid;
    try {
      await _client.from('wrong_words').delete().eq('user_id', uid);
      if (entries.isEmpty) return;
      await _client.from('wrong_words').insert([
        for (final e in entries) _mistakeToRow(uid, e),
      ]);
    } on PostgrestException catch (error, stack) {
      debugPrint('replaceAllMistakes failed: $error\n$stack');
      throw UserProgressSyncFailure(_mapPostgrest(error));
    } catch (error, stack) {
      debugPrint('replaceAllMistakes failed: $error\n$stack');
      throw const UserProgressSyncFailure(
        'Yanlışlar senkronlanamadı. Lütfen tekrar dene.',
      );
    }
  }

  Map<String, dynamic> _mistakeToRow(String uid, MistakeEntry entry) {
    return {
      'user_id': uid,
      'word_id': entry.wordId,
      'wrong_count': entry.wrongCount,
      'correct_since_miss_count': entry.correctSinceMissCount,
      'first_missed_at': entry.firstMissedAt.toUtc().toIso8601String(),
      'last_missed_at': entry.lastMissedAt.toUtc().toIso8601String(),
      'last_correct_at': entry.lastCorrectAt?.toUtc().toIso8601String(),
      'easiness': entry.easiness,
      'interval_days': entry.intervalDays,
      'repetition': entry.repetition,
    };
  }

  MistakeEntry _mistakeFromRow(Map<String, dynamic> row) {
    DateTime parseTs(Object? raw) {
      if (raw is String) return DateTime.parse(raw).toLocal();
      return DateTime.now();
    }

    return MistakeEntry(
      wordId: (row['word_id'] as num).toInt(),
      wrongCount: (row['wrong_count'] as num?)?.toInt() ?? 1,
      correctSinceMissCount:
          (row['correct_since_miss_count'] as num?)?.toInt() ?? 0,
      firstMissedAt: parseTs(row['first_missed_at']),
      lastMissedAt: parseTs(row['last_missed_at']),
      lastCorrectAt: row['last_correct_at'] == null
          ? null
          : parseTs(row['last_correct_at']),
      easiness: (row['easiness'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (row['interval_days'] as num?)?.toInt() ?? 0,
      repetition: (row['repetition'] as num?)?.toInt() ?? 0,
    );
  }

  String _mapPostgrest(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('permission') ||
        message.contains('rls') ||
        error.code == '42501') {
      return 'Veri erişim izni yok. Lütfen tekrar giriş yap.';
    }
    if (message.contains('network') || message.contains('timeout')) {
      return 'Bağlantı hatası. İnternetini kontrol edip tekrar dene.';
    }
    return 'Veri kaydı başarısız: ${error.message}';
  }
}
