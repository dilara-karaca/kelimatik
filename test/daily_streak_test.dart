import 'package:flutter_test/flutter_test.dart';

import 'package:kelimatik/domain/models/daily_streak_goal.dart';
import 'package:kelimatik/domain/models/daily_streak_state.dart';

void main() {
  final day = DateTime(2026, 8, 16, 12);

  test('first check-in starts streak at 1', () {
    final next = DailyStreakState.checkIn(
      current: 0,
      lastLoginDate: null,
      now: day,
    );
    expect(next.current, 1);
    expect(next.isAlive, isTrue);
    expect(next.lastLoginDate, DateTime(2026, 8, 16));
  });

  test('same-day check-in does not increment again', () {
    final next = DailyStreakState.checkIn(
      current: 4,
      lastLoginDate: DateTime(2026, 8, 16),
      now: day,
    );
    expect(next.current, 4);
    expect(next.isAlive, isTrue);
  });

  test('consecutive day increments streak', () {
    final next = DailyStreakState.checkIn(
      current: 4,
      lastLoginDate: DateTime(2026, 8, 15),
      now: day,
    );
    expect(next.current, 5);
    expect(next.isAlive, isTrue);
  });

  test('missed day restarts streak at 1', () {
    final next = DailyStreakState.checkIn(
      current: 12,
      lastLoginDate: DateTime(2026, 8, 14),
      now: day,
    );
    expect(next.current, 1);
    expect(next.isAlive, isTrue);
  });

  test('evaluate marks streak lost after a gap', () {
    final state = DailyStreakState.evaluate(
      current: 12,
      lastLoginDate: DateTime(2026, 8, 14),
      now: day,
    );
    expect(state.current, 0);
    expect(state.isLost, isTrue);
  });

  test('evaluate keeps streak alive through yesterday', () {
    final state = DailyStreakState.evaluate(
      current: 3,
      lastLoginDate: DateTime(2026, 8, 15),
      now: day,
    );
    expect(state.current, 3);
    expect(state.isAlive, isTrue);
  });

  test('parseDate keeps calendar YYYY-MM-DD without timezone shift', () {
    expect(
      DailyStreakState.parseDate('2026-10-04'),
      DateTime(2026, 10, 4),
    );
  });

  test('legacy today stamp is forgotten until the goal is complete', () {
    final stamped = DailyStreakState.evaluate(
      current: 2,
      lastLoginDate: DateTime(2026, 8, 16),
      now: day,
    );
    final pending = stamped.forgetUnqualifiedTodayStamp(
      todayGoalComplete: false,
      now: day,
    );
    expect(pending.current, 2);
    expect(pending.lastLoginDate, DateTime(2026, 8, 15));
    expect(pending.isAlive, isTrue);
  });

  test('qualify increments when today was only a login stamp', () {
    final next = DailyStreakState.qualify(
      current: 2,
      lastLoginDate: DateTime(2026, 8, 16),
      alreadyQualifiedToday: false,
      now: day,
    );
    expect(next.current, 3);
    expect(next.lastLoginDate, DateTime(2026, 8, 16));
  });

  test('qualify does not increment twice after the goal is done', () {
    final next = DailyStreakState.qualify(
      current: 3,
      lastLoginDate: DateTime(2026, 8, 16),
      alreadyQualifiedToday: true,
      now: day,
    );
    expect(next.current, 3);
  });

  test('qualify continues a yesterday streak', () {
    final next = DailyStreakState.qualify(
      current: 2,
      lastLoginDate: DateTime(2026, 8, 15),
      alreadyQualifiedToday: false,
      now: day,
    );
    expect(next.current, 3);
  });

  group('DailyStreakGoal', () {
    test('new day starts at zero regardless of stored count', () {
      final goal = DailyStreakGoal.forDay(
        answered: 7,
        storedDate: DateTime(2026, 8, 15),
        now: day,
      );
      expect(goal.answered, 0);
      expect(goal.isComplete, isFalse);
      expect(goal.date, DateTime(2026, 8, 16));
    });

    test('same day keeps stored count', () {
      final goal = DailyStreakGoal.forDay(
        answered: 7,
        storedDate: DateTime(2026, 8, 16),
        now: day,
      );
      expect(goal.answered, 7);
    });

    test('tenth answer completes the goal', () {
      var goal = DailyStreakGoal.emptyOn(day);
      for (var i = 0; i < DailyStreakGoal.target - 1; i++) {
        goal = goal.recordAnswer(now: day);
      }
      expect(goal.isComplete, isFalse);
      goal = goal.recordAnswer(now: day);
      expect(goal.answered, DailyStreakGoal.target);
      expect(goal.isComplete, isTrue);
    });

    test('new calendar day resets then counts the first answer', () {
      final previous = DailyStreakGoal(
        date: DateTime(2026, 8, 15),
        answered: 9,
      );
      final next = previous.recordAnswer(now: day);
      expect(next.answered, 1);
      expect(next.date, DateTime(2026, 8, 16));
      expect(next.isComplete, isFalse);
    });
  });
}
