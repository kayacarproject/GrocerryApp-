import '../../models/app_notification.dart';
import '../notification_repository.dart';
import 'mock_database.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<AppNotification>> getNotifications() async {
    await mockLatency(500);
    return List.unmodifiable(_db.notifications);
  }

  @override
  Future<void> markRead(String id) async {
    await mockLatency(150);
    final index = _db.notifications.indexWhere((n) => n.id == id);
    if (index >= 0) _db.notifications[index] = _db.notifications[index].markRead();
    await _db.save();
  }

  @override
  Future<void> markAllRead() async {
    await mockLatency(300);
    for (var i = 0; i < _db.notifications.length; i++) {
      _db.notifications[i] = _db.notifications[i].markRead();
    }
    await _db.save();
  }
}
