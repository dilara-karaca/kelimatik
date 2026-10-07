import 'daily_streak_state.dart';

/// Seven-day reward cycle for the streak celebration UI.
///
/// Cycle 1 = days 1–7, cycle 2 = 8–14, and so on. Labels follow the
/// actual weekdays of the current cycle, starting from the first filled day
/// — not a Monday–Sunday calendar week.
abstract final class StreakRewardCycle {
  static const int length = 7;

  static const List<String> weekdayShort = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  /// 1–7 inside the current cycle, or 0 when there is no streak.
  static int dayInCycle(int streak) {
    if (streak <= 0) return 0;
    return ((streak - 1) % length) + 1;
  }

  static bool chestUnlocked(int streak) => dayInCycle(streak) == length;

  static List<String> weekdayLabels({
    required int streak,
    required DateTime today,
  }) {
    final filled = dayInCycle(streak);
    final startOffset = filled <= 0 ? 0 : filled - 1;
    final start = DailyStreakState.dateOnly(today)
        .subtract(Duration(days: startOffset));
    return List<String>.generate(length, (index) {
      final day = start.add(Duration(days: index));
      return weekdayShort[day.weekday - 1];
    });
  }
}

/// Right-aligned digit pairs for a rolling number animation.
List<({String from, String to})> rollingDigitPairs(int from, int to) {
  final safeFrom = from < 0 ? 0 : from;
  final safeTo = to < 0 ? 0 : to;
  final toStr = safeTo.toString();
  final fromStr = safeFrom.toString().padLeft(toStr.length);
  return [
    for (var i = 0; i < toStr.length; i++)
      (from: fromStr[i], to: toStr[i]),
  ];
}

class StreakRenewalEvent {
  const StreakRenewalEvent({required this.from, required this.to});

  final int from;
  final int to;
}
