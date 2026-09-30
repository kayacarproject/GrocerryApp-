import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/delivery.dart';
import '../../models/order.dart';
import '../../models/pagination.dart';
import '../../models/payment.dart';

/// `GET /orders/:id/tracking` payload.
class OrderTracking {
  const OrderTracking({required this.status, required this.timeline, required this.delivery});

  factory OrderTracking.fromJson(Map<String, dynamic> json) => OrderTracking(
    status: OrderStatus.parse(Json.stringOrNull(json['status'])),
    timeline: Json.list(json['timeline'], OrderStatusEvent.fromJson),
    delivery: Delivery.fromJson(Json.map(json['delivery'])),
  );

  final OrderStatus status;
  final List<OrderStatusEvent> timeline;
  final Delivery delivery;
}

class OrderApiService {
  const OrderApiService(this._client);

  final ApiClient _client;

  static Order _order(Object? data) => Order.fromJson(Json.map(data));

  Future<Order> placeOrder(PlaceOrderRequest request) async {
    final response = await _client.post(
      ApiEndpoints.orders,
      body: request.toJson(),
      decoder: _order,
    );
    return response.data;
  }

  Future<PaginatedList<Order>> getOrders({int page = 1}) async {
    final response = await _client.get(
      ApiEndpoints.orders,
      query: {'page': page, 'per_page': 20},
      decoder: (data) => PaginatedList.fromData(data, Order.fromJson),
    );
    return response.data;
  }

  Future<Order> getOrder(String id) async =>
      (await _client.get(ApiEndpoints.order(id), decoder: _order)).data;

  Future<OrderTracking> getTracking(String id) async {
    final response = await _client.get(
      ApiEndpoints.orderTracking(id),
      decoder: (data) => OrderTracking.fromJson(Json.map(data)),
    );
    return response.data;
  }

  Future<Order> cancelOrder(String id, {String reason = 'Cancelled by customer'}) async {
    final response = await _client.post(
      ApiEndpoints.cancelOrder(id),
      body: {'reason': reason},
      decoder: _order,
    );
    return response.data;
  }

  Future<PaymentIntent> createPayment(String orderId) async {
    final response = await _client.post(
      ApiEndpoints.createPayment,
      body: {'order_id': Json.id(orderId)},
      decoder: (data) => PaymentIntent.fromJson(Json.map(data)),
    );
    return response.data;
  }

  Future<Payment> verifyPayment({
    required PaymentIntent intent,
    required String gatewayPaymentId,
    required String signature,
  }) async {
    final response = await _client.post(
      ApiEndpoints.verifyPayment,
      body: {
        'payment_id': Json.id(intent.paymentId),
        'gateway_order_id': intent.gatewayOrderId,
        'gateway_payment_id': gatewayPaymentId,
        'gateway_signature': signature,
      },
      decoder: (data) => Payment.fromJson(Json.map(data)),
    );
    return response.data;
  }
}
