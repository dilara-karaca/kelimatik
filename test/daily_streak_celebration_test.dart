import 'package:flutter_test/flutter_test.dart';
import 'package:kelimatik/data/repositories/syncing_daily_streak_repository.dart';
import 'package:kelimatik/domain/models/daily_streak_goal.dart';
import 'package:kelimatik/domain/models/daily_streak_state.dart';
import 'package:kelimatik/domain/models/study_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final day = DateTime(2026, 10, 4, 18);

  late SyncingDailyStreakRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      FeaturePrefsKeys.dailyStreak: 2,
      FeaturePrefsKeys.dailyStreakLastDate: '2026-10-03',
    });
    final prefs = await SharedPreferences.getInstance();
    repo = SyncingDailyStreakRepository(prefs);
  });

  test('tenth answer stores a one-shot celebration and increments once',
      () async {
    DailyStreakPlayResult? last;
    for (var i = 0; i < DailyStreakGoal.target; i++) {
      last = await repo.recordPlay(now: day);
    }
    expect(last!.didCheckIn, isTrue);
    expect(last.streak.current, 3);

    final event = await repo.takePendingCelebration(now: day);
    expect(event, isNotNull);
    expect(event!.from, 2);
    expect(event.to, 3);

    expect(await repo.takePendingCelebration(now: day), isNull);

    last = await repo.recordPlay(now: day);
    expect(last.didCheckIn, isFalse);
    expect(last.streak.current, 3);
  });

  test('missed screen still shows once after the goal is already complete',
      () async {
    for (var i = 0; i < DailyStreakGoal.target; i++) {
      await repo.recordPlay(now: day);
    }
    expect(repo.peekPendingCelebration(now: day), isNotNull);

    final event = await repo.takePendingCelebration(now: day);
    expect(event!.from, 2);
    expect(event.to, 3);
    expect(await repo.takePendingCelebration(now: day), isNull);
  });
}
