/// Local reminder types. Priority `1` is highest.
enum AppNotificationType {
  streakDanger(priority: 1, notificationId: 7101),
  dailyStreak(priority: 2, notificationId: 7102),
  incompleteGame(priority: 3, notificationId: 7103),
  livesRefilled(priority: 4, notificationId: 7104);

  const AppNotificationType({
    required this.priority,
    required this.notificationId,
  });

  /// Lower value is delivered first when the daily cap is applied.
  final int priority;
  final int notificationId;

  String get payload => name;

  static AppNotificationType? fromPayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final type in AppNotificationType.values) {
      if (type.payload == raw || type.name == raw) return type;
    }
    return null;
  }
}

abstract final class AppNotificationCopy {
  static String dailyStreak(int streak) =>
      '🔥 $streak günlük serin seni bekliyor! Bugünkü kelimelerini tamamla.';

  static String streakDanger(int streak) =>
      '🚨 $streak günlük serin tehlikede! Bugünkü kelimelerini tamamla.';

  static const livesRefilled =
      '❤️ Canların yenilendi! Yeni bir kelime turuna hazır mısın?';

  static const incompleteGame =
      '⚡ Oyunun yarım kaldı! Kaldığın yerden devam et.';
}
