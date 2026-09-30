import '../core/utils/json_utils.dart';
import 'address.dart';
import 'delivery.dart';
import 'payment.dart';
import 'price_summary.dart';

enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  preparing('Preparing'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus parse(String? value) {
    final normalized = value?.replaceAll('_', '').toLowerCase();
    return switch (normalized) {
      // Backend-only intermediate states mapped onto the customer timeline.
      'readyfordelivery' || 'packed' => OrderStatus.preparing,
      'pickedup' || 'shipped' => OrderStatus.outForDelivery,
      'canceled' || 'rejected' => OrderStatus.cancelled,
      _ => OrderStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == normalized,
        orElse: () => OrderStatus.pending,
      ),
    };
  }

  String get apiValue => switch (this) {
    OrderStatus.outForDelivery => 'out_for_delivery',
    _ => name,
  };

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;

  /// Position on the tracking timeline; cancelled orders are off-track.
  int get step => switch (this) {
    OrderStatus.pending => 0,
    OrderStatus.confirmed => 1,
    OrderStatus.preparing => 2,
    OrderStatus.outForDelivery => 3,
    OrderStatus.delivered => 4,
    OrderStatus.cancelled => -1,
  };
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unit,
    required this.quantity,
    required this.price,
    this.mrp,
    this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: Json.string(json['product_id']),
    name: Json.string(json['product_name'] ?? json['name']),
    imageUrl: Json.string(json['product_image'] ?? json['image_url']),
    unit: Json.string(json['unit']),
    quantity: Json.integer(json['quantity'], 1),
    price: Json.decimal(json['price']),
    mrp: Json.decimalOrNull(json['mrp']),
    lineTotal: Json.decimalOrNull(json['total'] ?? json['line_total']),
  );

  final String productId;
  final String name;
  final String imageUrl;
  final String unit;
  final int quantity;

  /// Unit price charged at the time of ordering.
  final double price;
  final double? mrp;
  final double? lineTotal;

  double get total => lineTotal ?? price * quantity;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': name,
    'product_image': imageUrl,
    'unit': unit,
    'quantity': quantity,
    'price': price,
    'mrp': mrp,
    'total': total,
  };
}

/// A status change on the tracking timeline.
class OrderStatusEvent {
  const OrderStatusEvent({required this.status, required this.at, this.note});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      OrderStatusEvent(
        status: OrderStatus.parse(Json.stringOrNull(json['status'])),
        at: Json.date(json['created_at'] ?? json['at']) ?? DateTime.now(),
        note: Json.stringOrNull(json['note']),
      );

  final OrderStatus status;
  final DateTime at;
  final String? note;

  Map<String, dynamic> toJson() => {
    'status': status.apiValue,
    'created_at': at.toUtc().toIso8601String(),
    'note': note,
  };
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.summary,
    required this.address,
    required this.payment,
    this.delivery = const Delivery(),
    this.statusHistory = const [],
    this.couponCode,
    this.notes,
    this.canCancel,
    this.cancelReason,
    this.cancelledAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final payment = Json.mapOrNull(json['payment']);
    final total = Json.decimal(json['total']);
    return Order(
      id: Json.string(json['id']),
      orderNumber: Json.string(json['order_number'], Json.string(json['id'])),
      status: OrderStatus.parse(Json.stringOrNull(json['status'])),
      createdAt: Json.date(json['created_at']) ?? DateTime.now(),
      items: Json.list(json['items'], OrderItem.fromJson),
      summary: PriceSummary.fromJson(json),
      address: Address.fromJson(Json.map(json['shipping_address'] ?? json['address'])),
      payment: payment != null
          ? Payment.fromJson(payment)
          : Payment(
              method: PaymentMethod.parse(Json.stringOrNull(json['payment_method'])),
              status: PaymentStatus.parse(Json.stringOrNull(json['payment_status'])),
              amount: total,
            ),
      delivery: Delivery.fromJson(Json.map(json['delivery'])),
      statusHistory: Json.list(json['timeline'] ?? json['status_history'], OrderStatusEvent.fromJson),
      couponCode: Json.stringOrNull(json['coupon_code']),
      notes: Json.stringOrNull(json['notes']),
      canCancel: json['can_cancel'] is bool ? json['can_cancel'] as bool : null,
      cancelReason: Json.stringOrNull(json['cancel_reason']),
      cancelledAt: Json.date(json['cancelled_at']),
      deliveredAt: Json.date(json['delivered_at']),
    );
  }

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;
  final PriceSummary summary;

  /// Snapshot of the delivery address at the time of ordering.
  final Address address;
  final Payment payment;
  final Delivery delivery;
  final List<OrderStatusEvent> statusHistory;
  final String? couponCode;
  final String? notes;

  /// Server's decision on whether the order may still be cancelled.
  final bool? canCancel;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime? deliveredAt;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  bool get isCancellable =>
      canCancel ?? (status == OrderStatus.pending || status == OrderStatus.confirmed);

  DateTime? timeOf(OrderStatus target) {
    if (target == OrderStatus.cancelled && cancelledAt != null) return cancelledAt;
    if (target == OrderStatus.delivered && deliveredAt != null) return deliveredAt;
    // Several backend states can map to one step; the first one counts.
    for (final event in statusHistory) {
      if (event.status == target) return event.at;
    }
    return null;
  }

  /// Merges live tracking data (timeline, partner) into this order.
  Order withTracking({
    required OrderStatus status,
    required List<OrderStatusEvent> timeline,
    required Delivery delivery,
  }) => Order(
    id: id,
    orderNumber: orderNumber,
    status: status,
    createdAt: createdAt,
    items: items,
    summary: summary,
    address: address,
    payment: payment,
    delivery: delivery,
    statusHistory: timeline,
    couponCode: couponCode,
    notes: notes,
    canCancel: canCancel,
    cancelReason: cancelReason,
    cancelledAt: cancelledAt,
    deliveredAt: delivery.deliveredAt ?? deliveredAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'status': status.apiValue,
    'created_at': createdAt.toUtc().toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    ...summary.toJson(),
    'coupon_code': couponCode,
    'shipping_address': address.toJson(),
    'payment': payment.toJson(),
    'payment_method': payment.method.apiValue,
    'payment_status': payment.status.name,
    'delivery': delivery.toJson(),
    'timeline': statusHistory.map((e) => e.toJson()).toList(),
    'notes': notes,
    'can_cancel': canCancel,
    'cancel_reason': cancelReason,
    'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
    'delivered_at': deliveredAt?.toUtc().toIso8601String(),
  };
}

/// What the app sends to place an order: references only. Prices, stock and
/// discounts are resolved by the server from its own records.
class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.addressId,
    required this.paymentMethod,
    this.slotId,
    this.couponCode,
    this.notes,
  });

  final String addressId;
  final PaymentMethod paymentMethod;

  /// Only used by the demo backend; the API delivers as soon as possible.
  final String? slotId;
  final String? couponCode;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'address_id': Json.id(addressId),
    'payment_method': paymentMethod.apiValue,
    if (couponCode != null && couponCode!.isNotEmpty) 'coupon_code': couponCode,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

/// Server-priced checkout summary for an address and optional coupon.
class CheckoutPreview {
  const CheckoutPreview({required this.summary, this.couponCode, this.address});

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) {
    final address = Json.mapOrNull(json['address']);
    return CheckoutPreview(
      summary: PriceSummary.fromJson(json),
      couponCode: Json.stringOrNull(json['coupon_code']),
      address: address == null ? null : Address.fromJson(address),
    );
  }

  final PriceSummary summary;
  final String? couponCode;
  final Address? address;
}
