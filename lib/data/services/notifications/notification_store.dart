import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/app_notification_type.dart';
import '../../../domain/models/daily_streak_state.dart';
import 'notification_planner.dart';

abstract final class NotificationPrefsKeys {
  static const lastStreakActivityAt = 'notif_last_streak_activity_at';
  static const incompleteLeftAt = 'notif_incomplete_left_at';
  static const incompleteSessionStartedAt =
      'notif_incomplete_session_started_at';
  static const leftWithPartialLives = 'notif_left_with_partial_lives';
  static const sentLog = 'notif_sent_log_v1';
  static const scheduled = 'notif_scheduled_v1';
}

class NotificationStore {
  NotificationStore(this._prefs);

  final SharedPreferences _prefs;

  DateTime? get lastStreakActivityAt =>
      _millis(_prefs.getInt(NotificationPrefsKeys.lastStreakActivityAt));

  Future<void> setLastStreakActivityAt(DateTime value) => _prefs.setInt(
        NotificationPrefsKeys.lastStreakActivityAt,
        value.millisecondsSinceEpoch,
      );

  DateTime? get incompleteLeftAt =>
      _millis(_prefs.getInt(NotificationPrefsKeys.incompleteLeftAt));

  DateTime? get incompleteSessionStartedAt => _millis(
        _prefs.getInt(NotificationPrefsKeys.incompleteSessionStartedAt),
      );

  Future<void> markIncomplete({
    required DateTime leftAt,
    required DateTime sessionStartedAt,
  }) async {
    await _prefs.setInt(
      NotificationPrefsKeys.incompleteLeftAt,
      leftAt.millisecondsSinceEpoch,
    );
    await _prefs.setInt(
      NotificationPrefsKeys.incompleteSessionStartedAt,
      sessionStartedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> clearIncomplete() async {
    await _prefs.remove(NotificationPrefsKeys.incompleteLeftAt);
    await _prefs.remove(NotificationPrefsKeys.incompleteSessionStartedAt);
  }

  bool get leftWithPartialLives =>
      _prefs.getBool(NotificationPrefsKeys.leftWithPartialLives) ?? false;

  Future<void> setLeftWithPartialLives(bool value) =>
      _prefs.setBool(NotificationPrefsKeys.leftWithPartialLives, value);

  Set<AppNotificationType> sentTypesFor(DateTime now) {
    final log = _readSentLog();
    if (log == null) return {};
    if (log.day != DailyStreakState.dateOnly(now)) return {};
    return log.types;
  }

  Future<void> markSent(AppNotificationType type, DateTime now) async {
    final today = DailyStreakState.dateOnly(now);
    final existing = _readSentLog();
    final types = <AppNotificationType>{
      if (existing != null && existing.day == today) ...existing.types,
      type,
    };
    await _prefs.setString(
      NotificationPrefsKeys.sentLog,
      jsonEncode({
        'date': DailyStreakState.formatDate(today),
        'types': types.map((t) => t.name).toList(),
      }),
    );
  }

  List<PlannedNotification> loadScheduled() {
    final raw = _prefs.getString(NotificationPrefsKeys.scheduled);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => e as Map<String, dynamic>)
          .map(_plannedFromJson)
          .whereType<PlannedNotification>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveScheduled(List<PlannedNotification> planned) {
    return _prefs.setString(
      NotificationPrefsKeys.scheduled,
      jsonEncode(planned.map(_plannedToJson).toList()),
    );
  }

  /// Notifications whose fire time has passed are treated as delivered.
  Future<void> reconcileDelivered(DateTime now) async {
    final scheduled = loadScheduled();
    if (scheduled.isEmpty) return;
    final remaining = <PlannedNotification>[];
    for (final item in scheduled) {
      if (!item.fireAt.isAfter(now)) {
        await markSent(item.type, item.fireAt);
      } else {
        remaining.add(item);
      }
    }
    await saveScheduled(remaining);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(NotificationPrefsKeys.lastStreakActivityAt),
      _prefs.remove(NotificationPrefsKeys.incompleteLeftAt),
      _prefs.remove(NotificationPrefsKeys.incompleteSessionStartedAt),
      _prefs.remove(NotificationPrefsKeys.leftWithPartialLives),
      _prefs.remove(NotificationPrefsKeys.sentLog),
      _prefs.remove(NotificationPrefsKeys.scheduled),
    ]);
  }

  _SentLog? _readSentLog() {
    final raw = _prefs.getString(NotificationPrefsKeys.sentLog);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final day = DailyStreakState.parseDate(map['date']);
      if (day == null) return null;
      final types = <AppNotificationType>{};
      final rawTypes = map['types'] as List<dynamic>? ?? const [];
      for (final name in rawTypes) {
        final type = AppNotificationType.fromPayload(name as String?);
        if (type != null) types.add(type);
      }
      return _SentLog(day: day, types: types);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _plannedToJson(PlannedNotification item) => {
        'type': item.type.name,
        'fireAt': item.fireAt.millisecondsSinceEpoch,
        'body': item.body,
        'streak': item.streak,
      };

  PlannedNotification? _plannedFromJson(Map<String, dynamic> json) {
    final type = AppNotificationType.fromPayload(json['type'] as String?);
    final fireRaw = json['fireAt'] as int?;
    final body = json['body'] as String?;
    if (type == null || fireRaw == null || body == null) return null;
    return PlannedNotification(
      type: type,
      fireAt: DateTime.fromMillisecondsSinceEpoch(fireRaw),
      body: body,
      streak: json['streak'] as int?,
    );
  }

  DateTime? _millis(int? value) =>
      value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
}

class _SentLog {
  const _SentLog({required this.day, required this.types});

  final DateTime day;
  final Set<AppNotificationType> types;
}
