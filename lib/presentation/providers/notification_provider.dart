import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/notifications/local_notification_client.dart';
import '../../data/services/notifications/notification_coordinator.dart';
import '../../data/services/notifications/notification_store.dart';
import 'dependency_providers.dart';

final localNotificationClientProvider = Provider<LocalNotificationClient>((ref) {
  return LocalNotificationClient();
});

final notificationStoreProvider = Provider<NotificationStore>((ref) {
  return NotificationStore(ref.watch(sharedPreferencesProvider));
});

final notificationCoordinatorProvider = Provider<NotificationCoordinator>((ref) {
  return NotificationCoordinator(
    store: ref.watch(notificationStoreProvider),
    client: ref.watch(localNotificationClientProvider),
  );
});
