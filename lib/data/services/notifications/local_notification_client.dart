import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../domain/models/app_notification_type.dart';
import 'notification_planner.dart';

class LocalNotificationClient {
  LocalNotificationClient({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'kelimatik_reminders';
  static const _channelName = 'Hatırlatmalar';
  static const _channelDescription = 'Seri, can ve oyun hatırlatmaları';

  var _initialized = false;
  var _tzReady = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    await _ensureTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: false,
      defaultPresentSound: false,
      defaultPresentBadge: false,
      defaultPresentBanner: false,
      defaultPresentList: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      final granted = await mac.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<bool> hasPermission() async {
    await initialize();
    if (kIsWeb) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }

    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      final options = await mac.checkPermissions();
      return options?.isEnabled ?? false;
    }

    return false;
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  /// Replaces OS schedules with [planned]. Unique IDs prevent duplicates.
  Future<void> applySchedule(List<PlannedNotification> planned) async {
    await initialize();
    if (kIsWeb) return;

    final keep = {for (final item in planned) item.type.notificationId};
    for (final type in AppNotificationType.values) {
      if (!keep.contains(type.notificationId)) {
        await _plugin.cancel(type.notificationId);
      }
    }

    for (final item in planned) {
      await _plugin.cancel(item.type.notificationId);
      await _zonedSchedule(item);
    }
  }

  Future<void> _zonedSchedule(PlannedNotification item) async {
    await _ensureTimeZone();
    final when = tz.TZDateTime(
      tz.local,
      item.fireAt.year,
      item.fireAt.month,
      item.fireAt.day,
      item.fireAt.hour,
      item.fireAt.minute,
      item.fireAt.second,
    );
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(item.body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        presentBadge: false,
      ),
    );

    await _plugin.zonedSchedule(
      item.type.notificationId,
      item.title,
      item.body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: item.type.payload,
    );
  }

  Future<void> _ensureTimeZone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      if (!kIsWeb) {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      }
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
    _tzReady = true;
  }
}
