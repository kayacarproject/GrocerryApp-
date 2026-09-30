import '../core/utils/json_utils.dart';

enum NotificationType {
  order,
  offer,
  system;

  /// Accepts specific API types such as `order_delivered` or `offer_new`.
  static NotificationType parse(String? value) {
    final type = value?.toLowerCase() ?? '';
    if (type.startsWith('order') || type.startsWith('payment')) return NotificationType.order;
    if (type.contains('offer') || type.contains('promo') || type.contains('coupon')) {
      return NotificationType.offer;
    }
    return NotificationType.system;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: Json.string(json['id']),
    title: Json.string(json['title']),
    body: Json.string(json['body']),
    type: NotificationType.parse(Json.stringOrNull(json['type'])),
    createdAt: Json.date(json['created_at']) ?? DateTime.now(),
    isRead: Json.boolean(json['is_read']),
    orderId: Json.stringOrNull(json['order_id'] ?? Json.map(json['data'])['order_id']),
  );

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  /// Order to open when the notification is tapped.
  final String? orderId;

  AppNotification markRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    createdAt: createdAt,
    isRead: true,
    orderId: orderId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'is_read': isRead,
    'data': {'order_id': orderId},
  };
}
