import '../../core/constants/app_constants.dart';
import 'daily_streak_state.dart';

/// Local calendar-day answer count toward the daily streak goal.
class DailyStreakGoal {
  const DailyStreakGoal({
    required this.date,
    required this.answered,
  });

  final DateTime date;
  final int answered;

  static const int target = AppConstants.dailyStreakGoalWords;

  static DailyStreakGoal emptyOn(DateTime day) => DailyStreakGoal(
        date: DailyStreakState.dateOnly(day),
        answered: 0,
      );

  bool get isComplete => answered >= target;

  /// Loads the stored count, resetting to 0 when [now] is a new calendar day.
  factory DailyStreakGoal.forDay({
    required int answered,
    required DateTime? storedDate,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = DailyStreakState.dateOnly(clock);
    final last = storedDate == null ? null : DailyStreakState.dateOnly(storedDate);
    if (last != today) {
      return DailyStreakGoal(date: today, answered: 0);
    }
    return DailyStreakGoal(
      date: today,
      answered: answered < 0 ? 0 : answered,
    );
  }

  /// Adds one answer. Same calendar day increments; a new day starts at 1.
  DailyStreakGoal recordAnswer({DateTime? now}) {
    final clock = now ?? DateTime.now();
    final today = DailyStreakState.dateOnly(clock);
    if (date != today) {
      return DailyStreakGoal(date: today, answered: 1);
    }
    return DailyStreakGoal(date: today, answered: answered + 1);
  }
}
