import '../../../core/constants/app_constants.dart';
import '../../../domain/models/daily_streak_state.dart';
import '../../../domain/models/lives_state.dart';
import 'local_notification_client.dart';
import 'notification_planner.dart';
import 'notification_store.dart';

class NotificationSnapshot {
  const NotificationSnapshot({
    required this.now,
    required this.inAppNotificationsEnabled,
    required this.appInForeground,
    required this.authenticated,
    required this.streak,
    required this.lives,
    required this.quizInProgress,
    required this.quizCompleted,
    required this.currentSessionStartedAt,
  });

  final DateTime now;
  final bool inAppNotificationsEnabled;
  final bool appInForeground;
  final bool authenticated;
  final DailyStreakState streak;
  final LivesState lives;
  final bool quizInProgress;
  final bool quizCompleted;
  final DateTime? currentSessionStartedAt;
}

class NotificationCoordinator {
  NotificationCoordinator({
    required NotificationStore store,
    required LocalNotificationClient client,
  })  : _store = store,
        _client = client;

  final NotificationStore _store;
  final LocalNotificationClient _client;

  Future<void> _lock = Future<void>.value();

  Future<void> _serialized(Future<void> Function() action) {
    final previous = _lock;
    final current = previous.then((_) => action());
    _lock = current.catchError((_) {});
    return current;
  }

  Future<void> initialize() => _serialized(() => _client.initialize());

  Future<bool> requestPermission() => _client.requestPermission();

  Future<void> recordStreakActivity(DateTime at) => _serialized(() async {
        await _store.setLastStreakActivityAt(at);
      });

  Future<void> onAppPaused(NotificationSnapshot snapshot) =>
      _serialized(() async {
        if (snapshot.quizInProgress &&
            snapshot.currentSessionStartedAt != null) {
          await _store.markIncomplete(
            leftAt: snapshot.now,
            sessionStartedAt: snapshot.currentSessionStartedAt!,
          );
        } else if (!snapshot.quizInProgress) {
          await _store.clearIncomplete();
        }

        final lives = snapshot.lives.refreshed(snapshot.now);
        await _store.setLeftWithPartialLives(
          lives.current < AppConstants.maxLives,
        );
        await _syncUnlocked(snapshot.copyWithForeground(false));
      });

  Future<void> onAppResumed(NotificationSnapshot snapshot) =>
      _serialized(() async {
        await _store.reconcileDelivered(snapshot.now);
        await _store.clearIncomplete();
        await _store.setLeftWithPartialLives(false);
        await _syncUnlocked(snapshot.copyWithForeground(true));
      });

  Future<void> sync(NotificationSnapshot snapshot) =>
      _serialized(() => _syncUnlocked(snapshot));

  Future<void> cancelAllAndClearUserState() => _serialized(() async {
        await _client.cancelAll();
        await _store.clearAll();
      });

  Future<void> _syncUnlocked(NotificationSnapshot snapshot) async {
    await _client.initialize();

    if (!snapshot.authenticated || !snapshot.inAppNotificationsEnabled) {
      await _client.cancelAll();
      await _store.saveScheduled(const []);
      return;
    }

    final osPermission = await _client.hasPermission();
    if (!osPermission) {
      await _client.cancelAll();
      await _store.saveScheduled(const []);
      return;
    }

    await _store.reconcileDelivered(snapshot.now);

    final input = NotificationPlannerInput(
      now: snapshot.now,
      inAppNotificationsEnabled: snapshot.inAppNotificationsEnabled,
      osPermissionGranted: true,
      appInForeground: snapshot.appInForeground,
      streak: snapshot.streak,
      lastStreakActivityAt: _store.lastStreakActivityAt,
      quizInProgress: snapshot.quizInProgress,
      incompleteLeftAt: _store.incompleteLeftAt,
      incompleteSessionStartedAt: _store.incompleteSessionStartedAt,
      currentSessionStartedAt: snapshot.currentSessionStartedAt,
      quizCompleted: snapshot.quizCompleted,
      lives: snapshot.lives,
      leftWithPartialLives: _store.leftWithPartialLives,
      sentToday: _store.sentTypesFor(snapshot.now),
    );

    final planned = NotificationPlanner.plan(input);
    await _client.applySchedule(planned);
    await _store.saveScheduled(planned);
  }
}

extension on NotificationSnapshot {
  NotificationSnapshot copyWithForeground(bool foreground) {
    return NotificationSnapshot(
      now: now,
      inAppNotificationsEnabled: inAppNotificationsEnabled,
      appInForeground: foreground,
      authenticated: authenticated,
      streak: streak,
      lives: lives,
      quizInProgress: quizInProgress,
      quizCompleted: quizCompleted,
      currentSessionStartedAt: currentSessionStartedAt,
    );
  }
}
