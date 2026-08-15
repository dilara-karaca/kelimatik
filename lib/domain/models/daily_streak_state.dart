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
    if (raw is DateTime) return dateOnly(raw.toLocal());
    if (raw is! String || raw.isEmpty) return null;
    // Accept `YYYY-MM-DD` or full timestamps.
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return dateOnly(parsed.toLocal());
  }
}
