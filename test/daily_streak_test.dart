import 'package:flutter_test/flutter_test.dart';

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
}
