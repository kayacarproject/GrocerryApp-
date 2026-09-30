import '../models/app_notification.dart';
import '../services/api/notification_api_service.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class RemoteNotificationRepository implements NotificationRepository {
  const RemoteNotificationRepository(this._api);

  final NotificationApiService _api;

  @override
  Future<List<AppNotification>> getNotifications() => _api.getNotifications();

  @override
  Future<void> markRead(String id) => _api.markRead(id);

  @override
  Future<void> markAllRead() => _api.markAllRead();
}
