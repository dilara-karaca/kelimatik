import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/daily_streak_goal.dart';
import '../../domain/models/daily_streak_state.dart';
import '../../domain/models/streak_reward_cycle.dart';
import '../../domain/models/study_mode.dart';
import '../services/user_progress_sync_service.dart';

class DailyStreakPlayResult {
  const DailyStreakPlayResult({
    required this.goal,
    required this.streak,
    required this.didCheckIn,
  });

  final DailyStreakGoal goal;
  final DailyStreakState streak;
  final bool didCheckIn;
}

/// Local cache + Supabase `profiles.daily_streak` / `last_daily_login_date`.
///
/// `last_daily_login_date` is the last local calendar day the 10-word goal
/// was completed — not an app-open stamp.
class SyncingDailyStreakRepository {
  SyncingDailyStreakRepository(this._prefs, [this._sync]);

  final SharedPreferences _prefs;
  final UserProgressSyncService? _sync;

  Future<void> _writeLock = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final done = _writeLock.then((_) => action());
    _writeLock = done.then((_) {}, onError: (_) {});
    return done;
  }

  /// Completes after every in-flight goal / check-in write.
  Future<void> waitForIdle() => _writeLock;

  DailyStreakState load() {
    final current = _prefs.getInt(FeaturePrefsKeys.dailyStreak) ?? 0;
    final lastRaw = _prefs.getString(FeaturePrefsKeys.dailyStreakLastDate);
    final last = DailyStreakState.parseDate(lastRaw);
    return DailyStreakState.evaluate(
      current: current,
      lastLoginDate: last,
    );
  }

  DailyStreakGoal loadGoal({DateTime? now}) {
    final answered = _prefs.getInt(FeaturePrefsKeys.dailyStreakGoalCount) ?? 0;
    final date = DailyStreakState.parseDate(
      _prefs.getString(FeaturePrefsKeys.dailyStreakGoalDate),
    );
    return DailyStreakGoal.forDay(
      answered: answered,
      storedDate: date,
      now: now,
    );
  }

  Future<void> replaceCache(DailyStreakState state) async {
    await _prefs.setInt(FeaturePrefsKeys.dailyStreak, state.current);
    final last = state.lastLoginDate;
    if (last == null) {
      await _prefs.remove(FeaturePrefsKeys.dailyStreakLastDate);
    } else {
      await _prefs.setString(
        FeaturePrefsKeys.dailyStreakLastDate,
        DailyStreakState.formatDate(last),
      );
    }
  }

  DateTime? _playQualifiedDate() => DailyStreakState.parseDate(
        _prefs.getString(FeaturePrefsKeys.dailyStreakQualifiedDate),
      );

  bool _playQualifiedToday(DateTime? now) {
    final qualified = _playQualifiedDate();
    if (qualified == null) return false;
    final today = DailyStreakState.dateOnly(now ?? DateTime.now());
    return qualified == today;
  }

  Future<void> _markPlayQualified(DateTime day) async {
    await _prefs.setString(
      FeaturePrefsKeys.dailyStreakQualifiedDate,
      DailyStreakState.formatDate(day),
    );
  }

  /// Cloud may still carry a same-day stamp from the old login check-in.
  Future<DailyStreakState> hydrateFromCloud(
    DailyStreakState cloud, {
    DateTime? now,
  }) {
    return _serialized(() async {
      final adjusted = cloud.forgetUnqualifiedTodayStamp(
        todayGoalComplete: _playQualifiedToday(now),
        now: now,
      );
      await replaceCache(adjusted);
      return (await _applyQualifyIfNeeded(now: now)).streak;
    });
  }

  Future<void> _persistGoal(DailyStreakGoal goal) async {
    await _prefs.setInt(FeaturePrefsKeys.dailyStreakGoalCount, goal.answered);
    await _prefs.setString(
      FeaturePrefsKeys.dailyStreakGoalDate,
      DailyStreakState.formatDate(goal.date),
    );
  }

  Future<DailyStreakPlayResult> _applyQualifyIfNeeded({DateTime? now}) async {
    final goal = loadGoal(now: now);
    final streak = load();
    if (!goal.isComplete || _playQualifiedToday(now)) {
      return DailyStreakPlayResult(
        goal: goal,
        streak: streak,
        didCheckIn: false,
      );
    }

    final clock = now ?? DateTime.now();
    final next = DailyStreakState.qualify(
      current: streak.current,
      lastLoginDate: streak.lastLoginDate,
      alreadyQualifiedToday: false,
      now: clock,
    );
    await replaceCache(next);
    await _markPlayQualified(DailyStreakState.dateOnly(clock));
    final sync = _sync;
    if (sync != null && sync.hasSession) {
      try {
        await sync.updateDailyStreak(next);
      } catch (error, stack) {
        debugPrint('daily streak cloud sync failed: $error\n$stack');
      }
    }
    return DailyStreakPlayResult(
      goal: goal,
      streak: next,
      didCheckIn: true,
    );
  }

  DateTime? _celebrationShownDate() => DailyStreakState.parseDate(
        _prefs.getString(FeaturePrefsKeys.dailyStreakCelebrationShownDate),
      );

  bool _celebrationShownToday(DateTime? now) {
    final shown = _celebrationShownDate();
    if (shown == null) return false;
    return shown == DailyStreakState.dateOnly(now ?? DateTime.now());
  }

  Future<void> _clearPendingCelebration() async {
    await Future.wait([
      _prefs.remove(FeaturePrefsKeys.dailyStreakCelebrationFrom),
      _prefs.remove(FeaturePrefsKeys.dailyStreakCelebrationTo),
      _prefs.remove(FeaturePrefsKeys.dailyStreakCelebrationDate),
    ]);
  }

  Future<void> _savePendingCelebration({
    required int from,
    required int to,
    DateTime? now,
  }) async {
    if (_celebrationShownToday(now)) return;
    final today = DailyStreakState.dateOnly(now ?? DateTime.now());
    await _prefs.setInt(FeaturePrefsKeys.dailyStreakCelebrationFrom, from);
    await _prefs.setInt(FeaturePrefsKeys.dailyStreakCelebrationTo, to);
    await _prefs.setString(
      FeaturePrefsKeys.dailyStreakCelebrationDate,
      DailyStreakState.formatDate(today),
    );
  }

  Future<void> _markCelebrationShown(DateTime? now) async {
    final today = DailyStreakState.dateOnly(now ?? DateTime.now());
    await _prefs.setString(
      FeaturePrefsKeys.dailyStreakCelebrationShownDate,
      DailyStreakState.formatDate(today),
    );
    await _clearPendingCelebration();
  }

  StreakRenewalEvent? peekPendingCelebration({DateTime? now}) {
    if (_celebrationShownToday(now)) return null;
    final today = DailyStreakState.dateOnly(now ?? DateTime.now());
    final date = DailyStreakState.parseDate(
      _prefs.getString(FeaturePrefsKeys.dailyStreakCelebrationDate),
    );
    if (date != today) return null;
    final to = _prefs.getInt(FeaturePrefsKeys.dailyStreakCelebrationTo);
    if (to == null) return null;
    final from = _prefs.getInt(FeaturePrefsKeys.dailyStreakCelebrationFrom) ?? 0;
    return StreakRenewalEvent(from: from, to: to);
  }

  /// Consumes today's unused celebration. If the 10-word goal is already
  /// done but the screen never ran, synthesizes the event once.
  Future<StreakRenewalEvent?> takePendingCelebration({DateTime? now}) {
    return _serialized(() async {
      final pending = peekPendingCelebration(now: now);
      if (pending != null) {
        await _markCelebrationShown(now);
        return pending;
      }
      if (_celebrationShownToday(now)) return null;
      final goal = loadGoal(now: now);
      if (!goal.isComplete) return null;
      final to = load().current;
      final from = to > 0 ? to - 1 : 0;
      await _markCelebrationShown(now);
      return StreakRenewalEvent(from: from, to: to);
    });
  }

  /// Adds one answer. When the 10-word goal is first reached, check-in runs.
  Future<DailyStreakPlayResult> recordPlay({DateTime? now}) {
    return _serialized(() async {
      final previousGoal = loadGoal(now: now);
      final streakBefore = load();
      final goal = previousGoal.recordAnswer(now: now);
      await _persistGoal(goal);
      final result = await _applyQualifyIfNeeded(now: now);
      if (!previousGoal.isComplete && goal.isComplete) {
        final to = result.streak.current;
        final from = result.didCheckIn
            ? streakBefore.current
            : (to > 0 ? to - 1 : 0);
        await _savePendingCelebration(from: from, to: to, now: now);
      }
      return result;
    });
  }

  /// Applies a skipped check-in if today's goal is already 10/10.
  Future<DailyStreakPlayResult> applyCompletedGoalCheckIn({DateTime? now}) {
    return _serialized(() => _applyQualifyIfNeeded(now: now));
  }
}
