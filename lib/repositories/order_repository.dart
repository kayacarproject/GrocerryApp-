import '../models/delivery.dart';
import '../models/order.dart';
import '../models/pagination.dart';
import '../models/payment.dart';
import '../services/api/order_api_service.dart';

abstract interface class OrderRepository {
  Future<List<DeliverySlot>> getDeliverySlots(String addressId);

  /// The server prices the order from its own catalog and the user's cart.
  Future<Order> placeOrder(PlaceOrderRequest request);

  /// Creates a server-side payment for an order before opening the gateway.
  Future<PaymentIntent> createPayment(String orderId);

  /// Server verifies the gateway result and marks the order paid.
  Future<Payment> verifyPayment({
    required PaymentIntent intent,
    required String gatewayPaymentId,
    required String signature,
  });

  Future<PaginatedList<Order>> getOrders({int page = 1});
  Future<Order> getOrder(String id);

  /// The order merged with its live timeline and delivery partner.
  Future<Order> getTracking(String id);
  Future<Order> cancelOrder(String id);
}

class RemoteOrderRepository implements OrderRepository {
  const RemoteOrderRepository(this._api);

  final OrderApiService _api;

  /// The API dispatches every order as soon as it is packed.
  @override
  Future<List<DeliverySlot>> getDeliverySlots(String addressId) async => const [
    DeliverySlot(
      id: 'asap',
      label: 'Deliver now',
      description: 'Dispatched as soon as your order is packed',
      isExpress: true,
    ),
  ];

  @override
  Future<Order> placeOrder(PlaceOrderRequest request) => _api.placeOrder(request);

  @override
  Future<PaymentIntent> createPayment(String orderId) => _api.createPayment(orderId);

  @override
  Future<Payment> verifyPayment({
    required PaymentIntent intent,
    required String gatewayPaymentId,
    required String signature,
  }) => _api.verifyPayment(intent: intent, gatewayPaymentId: gatewayPaymentId, signature: signature);

  @override
  Future<PaginatedList<Order>> getOrders({int page = 1}) => _api.getOrders(page: page);

  @override
  Future<Order> getOrder(String id) async {
    // Order details don't include the timeline; merge it in for display.
    final (order, tracking) = await (_api.getOrder(id), _api.getTracking(id)).wait;
    return order.withTracking(
      status: tracking.status,
      timeline: tracking.timeline,
      delivery: tracking.delivery,
    );
  }

  @override
  Future<Order> getTracking(String id) => getOrder(id);

  @override
  Future<Order> cancelOrder(String id) => _api.cancelOrder(id);
}
