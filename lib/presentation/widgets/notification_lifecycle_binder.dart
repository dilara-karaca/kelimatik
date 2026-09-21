import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/notifications/notification_coordinator.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_providers.dart';
import '../providers/lives_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';

/// Owns notification permission, lifecycle, and reschedule-on-boot.
class NotificationLifecycleBinder extends ConsumerStatefulWidget {
  const NotificationLifecycleBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationLifecycleBinder> createState() =>
      _NotificationLifecycleBinderState();
}

class _NotificationLifecycleBinderState
    extends ConsumerState<NotificationLifecycleBinder>
    with WidgetsBindingObserver {
  var _foreground = true;
  var _started = false;
  var _permissionAsked = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_foreground) {
          _foreground = true;
          unawaited(_onResumed());
        }
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_foreground) {
          _foreground = false;
          unawaited(_onPaused());
        }
    }
  }

  NotificationSnapshot _snapshot({required bool foreground}) {
    final quiz = ref.read(quizProvider);
    final auth = ref.read(authProvider);
    return NotificationSnapshot(
      now: DateTime.now(),
      inAppNotificationsEnabled:
          ref.read(appSettingsProvider).notificationsEnabled,
      appInForeground: foreground,
      authenticated: auth.status == AppAuthStatus.authenticated,
      streak: ref.read(dailyStreakProvider),
      lives: ref.read(livesProvider),
      quizInProgress: quiz.isInProgress,
      quizCompleted: quiz.showResult,
      currentSessionStartedAt: quiz.isInProgress ? quiz.startedAt : null,
    );
  }

  Future<void> _bootstrap() async {
    if (_started) return;
    _started = true;
    final coordinator = ref.read(notificationCoordinatorProvider);
    try {
      await coordinator.initialize();
      await _maybeRequestPermission();
      await coordinator.onAppResumed(_snapshot(foreground: true));
    } catch (_) {
      // Notifications must never block the app.
    }
  }

  Future<void> _maybeRequestPermission() async {
    if (_permissionAsked) return;
    final auth = ref.read(authProvider);
    final enabled = ref.read(appSettingsProvider).notificationsEnabled;
    if (auth.status != AppAuthStatus.authenticated || !enabled) return;
    _permissionAsked = true;
    try {
      await ref.read(notificationCoordinatorProvider).requestPermission();
    } catch (_) {}
  }

  Future<void> _onPaused() async {
    _debounce?.cancel();
    try {
      await ref
          .read(notificationCoordinatorProvider)
          .onAppPaused(_snapshot(foreground: false));
    } catch (_) {}
  }

  Future<void> _onResumed() async {
    _debounce?.cancel();
    try {
      await _maybeRequestPermission();
      await ref
          .read(notificationCoordinatorProvider)
          .onAppResumed(_snapshot(foreground: true));
    } catch (_) {}
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_syncNow());
    });
  }

  Future<void> _syncNow() async {
    try {
      await ref
          .read(notificationCoordinatorProvider)
          .sync(_snapshot(foreground: _foreground));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.status == AppAuthStatus.unauthenticated) {
        unawaited(
          ref
              .read(notificationCoordinatorProvider)
              .cancelAllAndClearUserState(),
        );
        return;
      }
      if (next.status == AppAuthStatus.authenticated) {
        unawaited(_maybeRequestPermission());
        _scheduleSync();
      }
    });

    ref.listen(appSettingsProvider, (previous, next) {
      if (next.notificationsEnabled &&
          previous?.notificationsEnabled == false) {
        _permissionAsked = false;
        unawaited(() async {
          await _maybeRequestPermission();
          await _syncNow();
        }());
        return;
      }
      _scheduleSync();
    });

    ref.listen(dailyStreakProvider, (previous, next) {
      _scheduleSync();
    });
    ref.listen(livesProvider, (previous, next) {
      _scheduleSync();
    });
    ref.listen(quizProvider, (previous, next) {
      _scheduleSync();
    });

    return widget.child;
  }
}
