import '../../../core/constants/app_constants.dart';
import '../../../domain/models/app_notification_type.dart';
import '../../../domain/models/daily_streak_state.dart';
import '../../../domain/models/lives_state.dart';

class PlannedNotification {
  const PlannedNotification({
    required this.type,
    required this.fireAt,
    required this.body,
    this.streak,
  });

  final AppNotificationType type;
  final DateTime fireAt;
  final String body;
  final int? streak;

  String get title => 'Kelimatik';
}

class NotificationPlannerInput {
  const NotificationPlannerInput({
    required this.now,
    required this.inAppNotificationsEnabled,
    required this.osPermissionGranted,
    required this.appInForeground,
    required this.streak,
    required this.lastStreakActivityAt,
    required this.quizInProgress,
    required this.incompleteLeftAt,
    required this.incompleteSessionStartedAt,
    required this.currentSessionStartedAt,
    required this.quizCompleted,
    required this.lives,
    required this.leftWithPartialLives,
    required this.sentToday,
  });

  final DateTime now;
  final bool inAppNotificationsEnabled;
  final bool osPermissionGranted;
  final bool appInForeground;
  final DailyStreakState streak;
  final DateTime? lastStreakActivityAt;
  final bool quizInProgress;
  final DateTime? incompleteLeftAt;
  final DateTime? incompleteSessionStartedAt;
  final DateTime? currentSessionStartedAt;
  final bool quizCompleted;
  final LivesState lives;
  final bool leftWithPartialLives;
  final Set<AppNotificationType> sentToday;
}

/// Pure scheduling rules. Does not change streak or lives math.
abstract final class NotificationPlanner {
  static const int maxPerDay = 2;
  static const int dangerHour = 21;
  static const int dangerMinute = 0;
  static const Duration incompleteDelay = Duration(minutes: 30);

  static List<PlannedNotification> plan(NotificationPlannerInput input) {
    if (!input.inAppNotificationsEnabled || !input.osPermissionGranted) {
      return const [];
    }

    final candidates = <PlannedNotification?>[
      if (shouldSendStreakDanger(input)) _danger(input),
      if (shouldSendDailyStreak(input)) _daily(input),
      if (shouldSendIncomplete(input)) _incomplete(input),
      if (shouldSendLives(input)) _lives(input),
    ].whereType<PlannedNotification>().toList();

    return applyDailyLimit(
      candidates: candidates,
      sentToday: input.sentToday,
      now: input.now,
    );
  }

  static bool hasCompletedStreakToday(DailyStreakState streak, DateTime now) {
    final last = streak.lastLoginDate;
    if (last == null) return false;
    return DailyStreakState.dateOnly(last) == DailyStreakState.dateOnly(now);
  }

  static bool isStreakActive(DailyStreakState streak) =>
      streak.isAlive && streak.current > 0;

  static bool shouldSendDailyStreak(NotificationPlannerInput input) {
    if (!isStreakActive(input.streak)) return false;
    final fireAt = nextDailyFireAt(input);
    if (fireAt == null) return false;
    return !_alreadySentOnFireDay(
      input: input,
      type: AppNotificationType.dailyStreak,
      fireAt: fireAt,
    );
  }

  static bool shouldSendStreakDanger(NotificationPlannerInput input) {
    if (!isStreakActive(input.streak)) return false;
    final fireAt = nextDangerFireAt(input);
    if (fireAt == null) return false;
    return !_alreadySentOnFireDay(
      input: input,
      type: AppNotificationType.streakDanger,
      fireAt: fireAt,
    );
  }

  static bool shouldSendIncomplete(NotificationPlannerInput input) {
    if (input.sentToday.contains(AppNotificationType.incompleteGame)) {
      return false;
    }
    if (input.appInForeground) return false;
    if (input.quizCompleted) return false;
    final leftAt = input.incompleteLeftAt;
    if (leftAt == null) return false;

    final incompleteSession = input.incompleteSessionStartedAt;
    final current = input.currentSessionStartedAt;
    if (incompleteSession != null &&
        current != null &&
        current.millisecondsSinceEpoch !=
            incompleteSession.millisecondsSinceEpoch) {
      return false;
    }

    final fireAt = leftAt.add(incompleteDelay);
    return fireAt.isAfter(input.now);
  }

  static bool shouldSendLives(NotificationPlannerInput input) {
    if (input.sentToday.contains(AppNotificationType.livesRefilled)) {
      return false;
    }
    if (input.appInForeground) return false;
    if (!input.leftWithPartialLives) return false;
    final fullAt = livesFullAt(input.lives, input.now);
    if (fullAt == null) return false;
    return fullAt.isAfter(input.now);
  }

  static DateTime? nextDailyFireAt(NotificationPlannerInput input) {
    final activity = input.lastStreakActivityAt;
    if (activity == null) return null;

    if (hasCompletedStreakToday(input.streak, input.now)) {
      final tomorrow =
          DailyStreakState.dateOnly(input.now).add(const Duration(days: 1));
      return DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        activity.hour,
        activity.minute,
      );
    }

    final today = DailyStreakState.dateOnly(input.now);
    final candidate = DateTime(
      today.year,
      today.month,
      today.day,
      activity.hour,
      activity.minute,
    );
    if (candidate.isAfter(input.now)) return candidate;
    return null;
  }

  static DateTime? nextDangerFireAt(NotificationPlannerInput input) {
    if (hasCompletedStreakToday(input.streak, input.now)) {
      final tomorrow =
          DailyStreakState.dateOnly(input.now).add(const Duration(days: 1));
      return DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        dangerHour,
        dangerMinute,
      );
    }

    final today = DailyStreakState.dateOnly(input.now);
    final candidate = DateTime(
      today.year,
      today.month,
      today.day,
      dangerHour,
      dangerMinute,
    );
    if (candidate.isAfter(input.now)) return candidate;
    return null;
  }

  static bool _alreadySentOnFireDay({
    required NotificationPlannerInput input,
    required AppNotificationType type,
    required DateTime fireAt,
  }) {
    final today = DailyStreakState.dateOnly(input.now);
    final fireDay = DailyStreakState.dateOnly(fireAt);
    if (fireDay != today) return false;
    return input.sentToday.contains(type);
  }

  static DateTime? livesFullAt(LivesState lives, DateTime now) {
    final refreshed = lives.refreshed(now);
    if (refreshed.isFull) return null;
    final untilNext = refreshed.timeUntilNextLife;
    if (untilNext == null) return null;
    final remainingAfterNext =
        AppConstants.maxLives - refreshed.current - 1;
    final extra = remainingAfterNext < 0
        ? Duration.zero
        : Duration(
            milliseconds: remainingAfterNext *
                AppConstants.lifeRegenDuration.inMilliseconds,
          );
    return now.add(untilNext + extra);
  }

  static List<PlannedNotification> applyDailyLimit({
    required List<PlannedNotification> candidates,
    required Set<AppNotificationType> sentToday,
    required DateTime now,
  }) {
    if (candidates.isEmpty) return const [];

    final today = DailyStreakState.dateOnly(now);
    final grouped = <DateTime, List<PlannedNotification>>{};
    for (final candidate in candidates) {
      final day = DailyStreakState.dateOnly(candidate.fireAt);
      grouped.putIfAbsent(day, () => []).add(candidate);
    }

    final selected = <PlannedNotification>[];
    for (final entry in grouped.entries) {
      final list = [...entry.value]..sort(
          (a, b) => a.type.priority.compareTo(b.type.priority),
        );
      final alreadySent = entry.key == today ? sentToday.length : 0;
      final remaining = maxPerDay - alreadySent;
      if (remaining <= 0) continue;
      selected.addAll(list.take(remaining));
    }

    selected.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return selected;
  }

  static PlannedNotification? _daily(NotificationPlannerInput input) {
    final fireAt = nextDailyFireAt(input);
    if (fireAt == null) return null;
    final streak = input.streak.current;
    return PlannedNotification(
      type: AppNotificationType.dailyStreak,
      fireAt: fireAt,
      body: AppNotificationCopy.dailyStreak(streak),
      streak: streak,
    );
  }

  static PlannedNotification? _danger(NotificationPlannerInput input) {
    final fireAt = nextDangerFireAt(input);
    if (fireAt == null) return null;
    final streak = input.streak.current;
    return PlannedNotification(
      type: AppNotificationType.streakDanger,
      fireAt: fireAt,
      body: AppNotificationCopy.streakDanger(streak),
      streak: streak,
    );
  }

  static PlannedNotification? _incomplete(NotificationPlannerInput input) {
    final leftAt = input.incompleteLeftAt;
    if (leftAt == null) return null;
    return PlannedNotification(
      type: AppNotificationType.incompleteGame,
      fireAt: leftAt.add(incompleteDelay),
      body: AppNotificationCopy.incompleteGame,
    );
  }

  static PlannedNotification? _lives(NotificationPlannerInput input) {
    final fireAt = livesFullAt(input.lives, input.now);
    if (fireAt == null) return null;
    return PlannedNotification(
      type: AppNotificationType.livesRefilled,
      fireAt: fireAt,
      body: AppNotificationCopy.livesRefilled,
    );
  }
}
