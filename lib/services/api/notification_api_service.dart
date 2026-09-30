import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/app_notification.dart';
import '../../models/pagination.dart';

class NotificationApiService {
  const NotificationApiService(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _client.get(
      ApiEndpoints.notifications,
      query: {'page': 1, 'per_page': 50},
      decoder: (data) => PaginatedList.fromData(data, AppNotification.fromJson),
    );
    return response.data.items;
  }

  Future<void> markRead(String id) async {
    await _client.patch(ApiEndpoints.notificationRead(id), decoder: (_) {});
  }

  Future<void> markAllRead() async {
    await _client.patch(ApiEndpoints.notificationsReadAll, decoder: (_) {});
  }
}
