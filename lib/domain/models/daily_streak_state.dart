/// Calendar-day login streak (local timezone).
class DailyStreakState {
  const DailyStreakState({
    required this.current,
    required this.lastLoginDate,
    required this.isAlive,
  });

  /// Consecutive days with a check-in. `0` means the streak is lost.
  final int current;

  /// Local calendar day of the last successful check-in, or null.
  final DateTime? lastLoginDate;

  /// True when the streak is still valid (checked in today or yesterday).
  final bool isAlive;

  bool get isLost => !isAlive || current <= 0;

  static const empty = DailyStreakState(
    current: 0,
    lastLoginDate: null,
    isAlive: false,
  );

  /// Evaluates streak for [now] without writing a new check-in.
  ///
  /// - Last login today or yesterday → alive with [current]
  /// - Older / missing → lost (`current: 0`)
  factory DailyStreakState.evaluate({
    required int current,
    required DateTime? lastLoginDate,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = dateOnly(clock);
    final last = lastLoginDate == null ? null : dateOnly(lastLoginDate);
    if (last == null) {
      return const DailyStreakState(
        current: 0,
        lastLoginDate: null,
        isAlive: false,
      );
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (last == today || last == yesterday) {
      final safe = current < 0 ? 0 : current;
      return DailyStreakState(
        current: safe,
        lastLoginDate: last,
        isAlive: safe > 0,
      );
    }
    return DailyStreakState(
      current: 0,
      lastLoginDate: last,
      isAlive: false,
    );
  }

  /// Drops a same-day stamp that did not come from completing the daily goal
  /// (legacy app-open check-in) so today's play can still increment.
  DailyStreakState forgetUnqualifiedTodayStamp({
    required bool todayGoalComplete,
    DateTime? now,
  }) {
    if (todayGoalComplete || current <= 0) return this;
    final today = dateOnly(now ?? DateTime.now());
    final last = lastLoginDate == null ? null : dateOnly(lastLoginDate!);
    if (last != today) return this;
    return DailyStreakState(
      current: current,
      lastLoginDate: today.subtract(const Duration(days: 1)),
      isAlive: true,
    );
  }

  /// Check-in used when today's 10-word goal is reached.
  ///
  /// A `lastLoginDate` of today from the old app-open logic is treated as
  /// yesterday unless [alreadyQualifiedToday] is true, so play can still
  /// increment the streak once.
  factory DailyStreakState.qualify({
    required int current,
    required DateTime? lastLoginDate,
    required bool alreadyQualifiedToday,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = dateOnly(clock);
    var last = lastLoginDate == null ? null : dateOnly(lastLoginDate);

    if (last == today && alreadyQualifiedToday) {
      return DailyStreakState.checkIn(
        current: current,
        lastLoginDate: last,
        now: clock,
      );
    }
    if (last == today) {
      last = today.subtract(const Duration(days: 1));
    }
    return DailyStreakState.checkIn(
      current: current,
      lastLoginDate: last,
      now: clock,
    );
  }

  /// Applies today's check-in. Same day does not increment again.
  factory DailyStreakState.checkIn({
    required int current,
    required DateTime? lastLoginDate,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = dateOnly(clock);
    final last = lastLoginDate == null ? null : dateOnly(lastLoginDate);

    if (last == today) {
      final safe = current < 1 ? 1 : current;
      return DailyStreakState(
        current: safe,
        lastLoginDate: today,
        isAlive: true,
      );
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (last == yesterday) {
      return DailyStreakState(
        current: (current < 0 ? 0 : current) + 1,
        lastLoginDate: today,
        isAlive: true,
      );
    }

    // Missed one or more days, or first ever check-in → streak restarts at 1.
    return DailyStreakState(
      current: 1,
      lastLoginDate: today,
      isAlive: true,
    );
  }

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// `YYYY-MM-DD` for Postgres `date` columns.
  static String formatDate(DateTime value) {
    final d = dateOnly(value);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime? parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      if (raw.isUtc &&
          raw.hour == 0 &&
          raw.minute == 0 &&
          raw.second == 0 &&
          raw.millisecond == 0) {
        return DateTime(raw.year, raw.month, raw.day);
      }
      return dateOnly(raw.toLocal());
    }
    if (raw is! String || raw.isEmpty) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return dateOnly(parsed.toLocal());
  }
}
