import 'package:flutter_test/flutter_test.dart';

import 'package:kelimatik/core/constants/app_constants.dart';
import 'package:kelimatik/data/services/notifications/notification_planner.dart';
import 'package:kelimatik/domain/models/app_notification_type.dart';
import 'package:kelimatik/domain/models/daily_streak_state.dart';
import 'package:kelimatik/domain/models/lives_state.dart';

void main() {
  final wednesdayMorning = DateTime(2026, 8, 19, 10, 0);
  final aliveStreak = DailyStreakState.evaluate(
    current: 12,
    lastLoginDate: DateTime(2026, 8, 18),
    now: wednesdayMorning,
  );
  final completedToday = DailyStreakState.checkIn(
    current: 12,
    lastLoginDate: DateTime(2026, 8, 18),
    now: wednesdayMorning,
  );
  const fullLives = LivesState.full;

  NotificationPlannerInput base({
    DateTime? now,
    DailyStreakState? streak,
    DateTime? lastStreakActivityAt,
    bool appInForeground = false,
    bool inAppNotificationsEnabled = true,
    bool osPermissionGranted = true,
    bool quizInProgress = false,
    DateTime? incompleteLeftAt,
    DateTime? incompleteSessionStartedAt,
    DateTime? currentSessionStartedAt,
    bool quizCompleted = false,
    LivesState lives = fullLives,
    bool leftWithPartialLives = false,
    Set<AppNotificationType> sentToday = const {},
  }) {
    return NotificationPlannerInput(
      now: now ?? wednesdayMorning,
      inAppNotificationsEnabled: inAppNotificationsEnabled,
      osPermissionGranted: osPermissionGranted,
      appInForeground: appInForeground,
      streak: streak ?? aliveStreak,
      lastStreakActivityAt: lastStreakActivityAt ?? DateTime(2026, 8, 18, 12, 37),
      quizInProgress: quizInProgress,
      incompleteLeftAt: incompleteLeftAt,
      incompleteSessionStartedAt: incompleteSessionStartedAt,
      currentSessionStartedAt: currentSessionStartedAt,
      quizCompleted: quizCompleted,
      lives: lives,
      leftWithPartialLives: leftWithPartialLives,
      sentToday: sentToday,
    );
  }

  group('daily streak reminder', () {
    test('schedules today at yesterday last-play clock time', () {
      final planned = NotificationPlanner.plan(base());
      final daily = planned.where(
        (p) => p.type == AppNotificationType.dailyStreak,
      );
      expect(daily, hasLength(1));
      expect(daily.first.fireAt, DateTime(2026, 8, 19, 12, 37));
      expect(
        daily.first.body,
        '🔥 12 günlük serin seni bekliyor! Bugünkü kelimelerini tamamla.',
      );
    });

    test('does not send today if streak already checked in today', () {
      final planned = NotificationPlanner.plan(
        base(streak: completedToday),
      );
      expect(
        planned.where(
          (p) =>
              p.type == AppNotificationType.dailyStreak &&
              p.fireAt.day == 19,
        ),
        isEmpty,
      );
    });

    test('after today check-in, schedules tomorrow at last activity time', () {
      final input = base(
        streak: completedToday,
        lastStreakActivityAt: DateTime(2026, 8, 19, 12, 37),
      );
      final fireAt = NotificationPlanner.nextDailyFireAt(input);
      expect(fireAt, DateTime(2026, 8, 20, 12, 37));
    });

    test('skips users with no active streak', () {
      final lost = DailyStreakState.evaluate(
        current: 12,
        lastLoginDate: DateTime(2026, 8, 16),
        now: wednesdayMorning,
      );
      final planned = NotificationPlanner.plan(base(streak: lost));
      expect(
        planned.where((p) => p.type == AppNotificationType.dailyStreak),
        isEmpty,
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.streakDanger),
        isEmpty,
      );
    });

    test('does not send after the clock time has passed', () {
      final planned = NotificationPlanner.plan(
        base(now: DateTime(2026, 8, 19, 13, 0)),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.dailyStreak),
        isEmpty,
      );
    });
  });

  group('streak danger reminder', () {
    test('schedules 21:00 if streak is alive and today is not checked in', () {
      final planned = NotificationPlanner.plan(base());
      final danger = planned.where(
        (p) => p.type == AppNotificationType.streakDanger,
      );
      expect(danger, hasLength(1));
      expect(danger.first.fireAt, DateTime(2026, 8, 19, 21, 0));
      expect(
        danger.first.body,
        '🚨 12 günlük serin tehlikede! Bugünkü kelimelerini tamamla.',
      );
    });

    test('does not send if user already checked in today', () {
      final planned = NotificationPlanner.plan(
        base(streak: completedToday),
      );
      expect(
        planned.any(
          (p) =>
              p.type == AppNotificationType.streakDanger &&
              p.fireAt.day == 19,
        ),
        isFalse,
      );
    });

    test('does not send after 21:00', () {
      final planned = NotificationPlanner.plan(
        base(now: DateTime(2026, 8, 19, 21, 5)),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.streakDanger),
        isEmpty,
      );
    });
  });

  group('incomplete game', () {
    test('schedules 30 minutes after leaving an unfinished game', () {
      final leftAt = DateTime(2026, 8, 19, 10, 5);
      final started = DateTime(2026, 8, 19, 10, 0);
      final planned = NotificationPlanner.plan(
        base(
          streak: completedToday,
          quizInProgress: true,
          incompleteLeftAt: leftAt,
          incompleteSessionStartedAt: started,
          currentSessionStartedAt: started,
        ),
      );
      final incomplete = planned.where(
        (p) => p.type == AppNotificationType.incompleteGame,
      );
      expect(incomplete, hasLength(1));
      expect(incomplete.first.fireAt, DateTime(2026, 8, 19, 10, 35));
    });

    test('does not send if the user is back in the app', () {
      final started = DateTime(2026, 8, 19, 10, 0);
      final planned = NotificationPlanner.plan(
        base(
          appInForeground: true,
          quizInProgress: true,
          incompleteLeftAt: DateTime(2026, 8, 19, 10, 5),
          incompleteSessionStartedAt: started,
          currentSessionStartedAt: started,
        ),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.incompleteGame),
        isEmpty,
      );
    });

    test('does not send if a newer session replaced the old one', () {
      final planned = NotificationPlanner.plan(
        base(
          streak: completedToday,
          quizInProgress: true,
          incompleteLeftAt: DateTime(2026, 8, 19, 10, 5),
          incompleteSessionStartedAt: DateTime(2026, 8, 19, 10, 0),
          currentSessionStartedAt: DateTime(2026, 8, 19, 11, 0),
        ),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.incompleteGame),
        isEmpty,
      );
    });

    test('does not send a second incomplete notification the same day', () {
      final started = DateTime(2026, 8, 19, 10, 0);
      final planned = NotificationPlanner.plan(
        base(
          quizInProgress: true,
          incompleteLeftAt: DateTime(2026, 8, 19, 10, 5),
          incompleteSessionStartedAt: started,
          currentSessionStartedAt: started,
          sentToday: {AppNotificationType.incompleteGame},
        ),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.incompleteGame),
        isEmpty,
      );
    });
  });

  group('lives refilled', () {
    test('schedules when lives will reach 5 after leaving with a deficit', () {
      final now = DateTime(2026, 8, 19, 10, 0);
      final lives = LivesState(
        current: 3,
        regenStartedAt: now,
        now: now,
      );
      final planned = NotificationPlanner.plan(
        base(
          now: now,
          lives: lives,
          leftWithPartialLives: true,
          streak: completedToday,
        ),
      );
      final livesNotif = planned.where(
        (p) => p.type == AppNotificationType.livesRefilled,
      );
      expect(livesNotif, hasLength(1));
      expect(
        livesNotif.first.fireAt,
        now.add(AppConstants.lifeRegenDuration * 2),
      );
    });

    test('does not send if the user left with full lives', () {
      final planned = NotificationPlanner.plan(
        base(
          leftWithPartialLives: false,
          lives: const LivesState(current: 3),
        ),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.livesRefilled),
        isEmpty,
      );
    });

    test('does not send while the app is in the foreground', () {
      final now = DateTime(2026, 8, 19, 10, 0);
      final planned = NotificationPlanner.plan(
        base(
          now: now,
          appInForeground: true,
          lives: LivesState(current: 3, regenStartedAt: now, now: now),
          leftWithPartialLives: true,
        ),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.livesRefilled),
        isEmpty,
      );
    });

    test('caps lives refill to once per day', () {
      final now = DateTime(2026, 8, 19, 10, 0);
      final planned = NotificationPlanner.plan(
        base(
          now: now,
          lives: LivesState(current: 3, regenStartedAt: now, now: now),
          leftWithPartialLives: true,
          sentToday: {AppNotificationType.livesRefilled},
        ),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.livesRefilled),
        isEmpty,
      );
    });
  });

  group('daily cap and priority', () {
    test('keeps danger over daily when both compete today', () {
      final planned = NotificationPlanner.plan(base());
      expect(
        planned.map((p) => p.type),
        containsAll([
          AppNotificationType.streakDanger,
          AppNotificationType.dailyStreak,
        ]),
      );
    });

    test('after daily was sent, remaining slot goes to danger not lives', () {
      final now = DateTime(2026, 8, 19, 10, 0);
      final planned = NotificationPlanner.plan(
        base(
          now: now,
          lives: LivesState(current: 3, regenStartedAt: now, now: now),
          leftWithPartialLives: true,
          sentToday: {AppNotificationType.dailyStreak},
        ),
      );
      expect(
        planned.map((p) => p.type),
        contains(AppNotificationType.streakDanger),
      );
      expect(
        planned.where((p) => p.type == AppNotificationType.livesRefilled),
        isEmpty,
      );
    });

    test('after two notifications sent, nothing else is scheduled today', () {
      final now = DateTime(2026, 8, 19, 10, 0);
      final started = DateTime(2026, 8, 19, 9, 50);
      final planned = NotificationPlanner.plan(
        base(
          now: now,
          lives: LivesState(current: 3, regenStartedAt: now, now: now),
          leftWithPartialLives: true,
          quizInProgress: true,
          incompleteLeftAt: DateTime(2026, 8, 19, 10, 0),
          incompleteSessionStartedAt: started,
          currentSessionStartedAt: started,
          sentToday: {
            AppNotificationType.dailyStreak,
            AppNotificationType.incompleteGame,
          },
        ),
      );
      expect(
        planned.where(
          (p) => DailyStreakState.dateOnly(p.fireAt) == DateTime(2026, 8, 19),
        ),
        isEmpty,
      );
    });

    test('does not send without permission or in-app toggle', () {
      expect(NotificationPlanner.plan(base(osPermissionGranted: false)), isEmpty);
      expect(
        NotificationPlanner.plan(base(inAppNotificationsEnabled: false)),
        isEmpty,
      );
    });
  });

  group('livesFullAt', () {
    test('uses existing regen duration without changing lives math', () {
      final now = DateTime(2026, 8, 19, 12);
      final lives = LivesState(
        current: 4,
        regenStartedAt: now,
        now: now,
      );
      expect(
        NotificationPlanner.livesFullAt(lives, now),
        now.add(AppConstants.lifeRegenDuration),
      );
    });
  });
}
