import '../../core/network/api_exception.dart';
import '../../models/app_notification.dart';
import '../../models/delivery.dart';
import '../../models/order.dart';
import '../../models/pagination.dart';
import '../../models/payment.dart';
import '../order_repository.dart';
import 'mock_database.dart';

class MockOrderRepository implements OrderRepository {
  MockOrderRepository(this._db);

  final MockDatabase _db;

  Order _find(String id) {
    for (final order in _db.orders) {
      if (order.id == id) return order;
    }
    throw const ApiException(
      type: ApiErrorType.notFound,
      statusCode: 404,
      message: 'We could not find this order.',
    );
  }

  void _replace(Order order) {
    final index = _db.orders.indexWhere((o) => o.id == order.id);
    _db.orders[index] = order;
  }

  @override
  Future<List<DeliverySlot>> getDeliverySlots(String addressId) async {
    await mockLatency(400);
    return _db.deliverySlots();
  }

  @override
  Future<Order> placeOrder(PlaceOrderRequest request) async {
    await mockLatency(1200);
    final cart = _db.priceCart();
    if (cart.isEmpty) throw mockError('Your cart is empty.');

    final address = _db.addresses.where((a) => a.id == request.addressId).firstOrNull;
    if (address == null) throw mockError('Please select a delivery address.');

    final slots = _db.deliverySlots();
    final slot = request.slotId == null
        ? slots.first
        : slots.where((s) => s.id == request.slotId).firstOrNull;
    if (slot == null || !slot.isAvailable) {
      throw mockError('That delivery slot is no longer available.');
    }

    for (final item in cart.items) {
      if (item.quantity > item.product.stock) {
        throw mockError('${item.product.name} has only ${item.product.stock} left.');
      }
    }

    // Same rules as checkout preview; throws for an invalid coupon.
    final summary = _db.preview(couponCode: request.couponCode);
    final now = DateTime.now();
    final order = Order(
      id: 'o${now.millisecondsSinceEpoch}',
      orderNumber: _db.nextOrderNumber(),
      status: OrderStatus.pending,
      createdAt: now,
      items: [
        for (final item in cart.items)
          OrderItem(
            productId: item.product.id,
            name: item.product.name,
            imageUrl: item.product.imageUrl,
            unit: item.product.unit,
            quantity: item.quantity,
            price: item.product.price,
            mrp: item.product.mrp,
          ),
      ],
      summary: summary,
      address: address,
      payment: Payment(
        id: 'pay${now.millisecondsSinceEpoch}',
        method: request.paymentMethod,
        status: PaymentStatus.pending,
        amount: summary.total,
      ),
      delivery: Delivery(
        slot: slot,
        estimatedAt: slot.isExpress ? now.add(const Duration(minutes: 15)) : null,
      ),
      couponCode: request.couponCode,
      notes: request.notes,
      statusHistory: [OrderStatusEvent(status: OrderStatus.pending, at: now)],
    );

    _db.orders.insert(0, order);
    _db.cartLines.clear();
    _db.notifications.insert(
      0,
      AppNotification(
        id: 'n${now.millisecondsSinceEpoch}',
        title: 'Order placed 🎉',
        body: 'Order #${order.orderNumber} has been placed successfully.',
        type: NotificationType.order,
        orderId: order.id,
        createdAt: now,
      ),
    );
    await _db.save();
    return _db.withLiveStatus(order);
  }

  @override
  Future<PaymentIntent> createPayment(String orderId) async {
    await mockLatency(500);
    final order = _find(orderId);
    return PaymentIntent(
      paymentId: order.payment.id,
      orderId: order.id,
      gatewayOrderId: 'mock_order_${order.id}',
      amount: order.summary.total,
      gateway: 'mock',
    );
  }

  @override
  Future<Payment> verifyPayment({
    required PaymentIntent intent,
    required String gatewayPaymentId,
    required String signature,
  }) async {
    await mockLatency(700);
    if (signature != 'mock_success') throw mockError('Payment verification failed');
    final order = _find(intent.orderId);
    final payment = Payment(
      id: order.payment.id,
      method: order.payment.method,
      status: PaymentStatus.paid,
      amount: order.payment.amount,
      transactionId: gatewayPaymentId,
      paidAt: DateTime.now(),
    );
    _replace(Order.fromJson({...order.toJson(), 'payment': payment.toJson()}));
    await _db.save();
    return payment;
  }

  @override
  Future<PaginatedList<Order>> getOrders({int page = 1}) async {
    await mockLatency(600);
    final orders = _db.orders.map(_db.withLiveStatus).toList();
    return PaginatedList(
      items: orders,
      pagination: Pagination(
        page: 1,
        perPage: orders.length,
        total: orders.length,
        lastPage: 1,
      ),
    );
  }

  @override
  Future<Order> getOrder(String id) async {
    await mockLatency(400);
    return _db.withLiveStatus(_find(id));
  }

  @override
  Future<Order> getTracking(String id) async {
    await mockLatency(250);
    return _db.withLiveStatus(_find(id));
  }

  @override
  Future<Order> cancelOrder(String id) async {
    await mockLatency(700);
    final live = _db.withLiveStatus(_find(id));
    if (!live.isCancellable) {
      throw mockError('This order is already being prepared and can\'t be cancelled.');
    }
    final now = DateTime.now();
    final cancelled = Order.fromJson({
      ...live.toJson(),
      'status': OrderStatus.cancelled.apiValue,
      'timeline': [
        ...live.statusHistory.map((e) => e.toJson()),
        OrderStatusEvent(status: OrderStatus.cancelled, at: now).toJson(),
      ],
      'can_cancel': false,
      'cancel_reason': 'Cancelled by customer',
      'cancelled_at': now.toUtc().toIso8601String(),
      if (live.payment.status == PaymentStatus.paid)
        'payment': Payment(
          id: live.payment.id,
          method: live.payment.method,
          status: PaymentStatus.refunded,
          amount: live.payment.amount,
          transactionId: live.payment.transactionId,
        ).toJson(),
    });
    _replace(cancelled);
    await _db.save();
    return cancelled;
  }
}
