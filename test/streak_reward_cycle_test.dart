import 'package:flutter_test/flutter_test.dart';

import 'package:kelimatik/domain/models/streak_reward_cycle.dart';

void main() {
  test('day in cycle wraps every 7 streak days', () {
    expect(StreakRewardCycle.dayInCycle(0), 0);
    expect(StreakRewardCycle.dayInCycle(1), 1);
    expect(StreakRewardCycle.dayInCycle(4), 4);
    expect(StreakRewardCycle.dayInCycle(7), 7);
    expect(StreakRewardCycle.dayInCycle(8), 1);
    expect(StreakRewardCycle.dayInCycle(14), 7);
    expect(StreakRewardCycle.dayInCycle(15), 1);
  });

  test('chest unlocks on 7, 14, 21', () {
    expect(StreakRewardCycle.chestUnlocked(6), isFalse);
    expect(StreakRewardCycle.chestUnlocked(7), isTrue);
    expect(StreakRewardCycle.chestUnlocked(14), isTrue);
    expect(StreakRewardCycle.chestUnlocked(21), isTrue);
    expect(StreakRewardCycle.chestUnlocked(8), isFalse);
  });

  test('weekday labels start from the first day of the current cycle', () {
    final friday = DateTime(2026, 10, 2);
    final labels = StreakRewardCycle.weekdayLabels(
      streak: 4,
      today: friday,
    );
    expect(labels, ['Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz', 'Pzt']);
  });

  test('rolling digits keep unchanged places still', () {
    expect(
      rollingDigitPairs(25, 26).map((p) => '${p.from}->${p.to}'),
      ['2->2', '5->6'],
    );
  });

  test('rolling digits handle carry and extra place', () {
    expect(
      rollingDigitPairs(29, 30).map((p) => '${p.from}->${p.to}'),
      ['2->3', '9->0'],
    );
    expect(
      rollingDigitPairs(99, 100).map((p) => '${p.from}->${p.to}'),
      [' ->1', '9->0', '9->0'],
    );
  });
}
