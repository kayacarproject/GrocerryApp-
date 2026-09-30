import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/local_cache.dart';
import '../../core/utils/json_utils.dart';
import '../../models/address.dart';
import '../../models/app_notification.dart';
import '../../models/cart.dart';
import '../../models/coupon.dart';
import '../../models/delivery.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../models/price_summary.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import 'mock_catalog_data.dart';

/// Simulated network latency for the demo backend.
Future<void> mockLatency([int milliseconds = 450]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

ApiException mockError(String message, [ApiErrorType type = ApiErrorType.validation]) =>
    ApiException(type: type, message: message, statusCode: 422);

/// In-process stand-in for the backend. It owns all business rules the real
/// server would own — pricing, coupon validation, stock checks and order
/// status — and persists its state locally so demos survive restarts.
class MockDatabase {
  MockDatabase(this._cache) {
    _load();
  }

  static const _stateKey = 'mock_backend.state';
  static const freeDeliveryThreshold = 199.0;
  static const deliveryFee = 25.0;
  static const taxRate = 0.05;

  final LocalCache _cache;

  final Map<String, Product> products = {for (final p in mockProducts) p.id: p};

  final List<_UserRecord> _users = [];
  final Map<String, int> cartLines = {};
  final Map<String, DateTime> wishlist = {};
  final List<Address> addresses = [];
  final List<Order> orders = [];
  final List<AppNotification> notifications = [];
  final Map<String, String> pendingOtps = {};

  static final coupons = <Coupon>[
    Coupon(
      code: 'WELCOME50',
      description: 'Up to ₹100 off on orders above ₹199',
      discountType: DiscountType.percentage,
      value: 50,
      maxDiscount: 100,
      minOrderValue: 199,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    ),
    Coupon(
      code: 'FRESH20',
      description: 'Up to ₹75 off on orders above ₹299',
      discountType: DiscountType.percentage,
      value: 20,
      maxDiscount: 75,
      minOrderValue: 299,
      expiresAt: DateTime.now().add(const Duration(days: 14)),
    ),
    Coupon(
      code: 'SAVE30',
      description: 'On orders above ₹249',
      discountType: DiscountType.flat,
      value: 30,
      minOrderValue: 249,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    ),
    Coupon(
      code: 'MEGA100',
      description: 'On orders above ₹999',
      discountType: DiscountType.flat,
      value: 100,
      minOrderValue: 999,
      expiresAt: DateTime.now().add(const Duration(days: 10)),
    ),
  ];

  // ---------------------------------------------------------------- users

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode('basketly-demo::$password')).toString();

  User? userById(String id) {
    for (final record in _users) {
      if (record.user.id == id) return record.user;
    }
    return null;
  }

  User? authenticate(String identifier, String password) {
    final key = identifier.trim().toLowerCase();
    for (final record in _users) {
      final matches = record.user.email.toLowerCase() == key || record.user.phone == key;
      if (matches && record.passwordHash == hashPassword(password)) return record.user;
    }
    return null;
  }

  User? findByIdentifier(String identifier) {
    final key = identifier.trim().toLowerCase();
    for (final record in _users) {
      if (record.user.email.toLowerCase() == key || record.user.phone == key) {
        return record.user;
      }
    }
    return null;
  }

  void addUser(User user, String password) =>
      _users.add(_UserRecord(user, hashPassword(password)));

  void updateUser(User user) {
    final index = _users.indexWhere((r) => r.user.id == user.id);
    if (index >= 0) _users[index] = _UserRecord(user, _users[index].passwordHash);
  }

  void setPassword(String userId, String password) {
    final index = _users.indexWhere((r) => r.user.id == userId);
    if (index >= 0) _users[index] = _UserRecord(_users[index].user, hashPassword(password));
  }

  // ---------------------------------------------------------------- pricing

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  double get cartSubtotal => cartLines.entries.fold(
    0,
    (sum, e) => sum + (products[e.key]?.price ?? 0) * e.value,
  );

  double couponDiscountFor(Coupon coupon, double subtotal) {
    if (subtotal < coupon.minOrderValue) return 0;
    final raw = coupon.discountType == DiscountType.flat
        ? coupon.value
        : subtotal * coupon.value / 100;
    final capped = coupon.maxDiscount == null ? raw : raw.clamp(0, coupon.maxDiscount!);
    return _round(capped.toDouble());
  }

  Coupon? couponByCode(String code) {
    for (final c in coupons) {
      if (c.code == code.trim().toUpperCase()) return c;
    }
    return null;
  }

  /// Re-prices the cart from catalog prices, like the real `/cart` endpoint:
  /// item totals only, no delivery, tax or coupon.
  Cart priceCart() {
    final items = <CartItem>[];
    var mrpTotal = 0.0;
    var subtotal = 0.0;
    for (final entry in cartLines.entries) {
      final product = products[entry.key];
      if (product == null) continue;
      final line = product.price * entry.value;
      subtotal += line;
      mrpTotal += product.mrp * entry.value;
      items.add(
        CartItem(
          id: 'ci-${product.id}',
          product: product,
          quantity: entry.value,
          lineTotal: _round(line),
        ),
      );
    }
    return Cart(
      items: items,
      summary: PriceSummary(
        itemsMrp: _round(mrpTotal),
        productDiscount: _round(mrpTotal - subtotal),
        total: _round(subtotal),
        includesCharges: false,
      ),
    );
  }

  /// Full bill as `/checkout/preview` computes it. Throws for bad coupons.
  PriceSummary preview({String? couponCode}) {
    final cart = priceCart();
    if (cart.isEmpty) throw mockError('Your cart is empty');
    final subtotal = cart.summary.subtotal;

    var couponDiscount = 0.0;
    if (couponCode != null && couponCode.isNotEmpty) {
      final coupon = couponByCode(couponCode);
      if (coupon == null) throw mockError('This coupon code is not valid');
      if (subtotal < coupon.minOrderValue) {
        throw mockError(
          'Add items worth ₹${(coupon.minOrderValue - subtotal).ceil()} more to use ${coupon.code}',
        );
      }
      couponDiscount = couponDiscountFor(coupon, subtotal);
    }
    final fee = subtotal >= freeDeliveryThreshold ? 0.0 : deliveryFee;
    final tax = _round((subtotal - couponDiscount) * taxRate);
    return PriceSummary(
      itemsMrp: cart.summary.itemsMrp,
      productDiscount: cart.summary.productDiscount,
      couponDiscount: couponDiscount,
      deliveryFee: fee,
      tax: tax,
      total: _round(subtotal - couponDiscount + fee + tax),
      freeDeliveryThreshold: freeDeliveryThreshold,
    );
  }

  // ---------------------------------------------------------------- delivery

  List<DeliverySlot> deliverySlots() {
    final now = DateTime.now();
    DeliverySlot window(String id, int dayOffset, int startHour, int endHour) {
      final day = dayOffset == 0 ? 'Today' : 'Tomorrow';
      String hour(int h) => '${h > 12 ? h - 12 : h} ${h >= 12 ? 'PM' : 'AM'}';
      final available = dayOffset > 0 || now.hour < startHour - 1;
      return DeliverySlot(
        id: id,
        label: '$day, ${hour(startHour)} – ${hour(endHour)}',
        description: available ? 'Free slot delivery' : 'Slot full',
        isAvailable: available,
      );
    }

    return [
      const DeliverySlot(
        id: 'express',
        label: 'Express delivery',
        description: 'Arrives in 10–15 minutes',
        isExpress: true,
      ),
      window('today-18', 0, 18, 20),
      window('today-20', 0, 20, 22),
      window('tomorrow-7', 1, 7, 9),
      window('tomorrow-9', 1, 9, 11),
    ];
  }

  // ---------------------------------------------------------------- orders

  static const _partner = DeliveryPartner(
    name: 'Ravi Kumar',
    phone: '+919876543210',
    vehicleNumber: 'KA 01 EZ 4821',
    rating: 4.8,
  );

  // Seconds after placement at which each status is reached (demo timeline).
  static const _timeline = <OrderStatus, int>{
    OrderStatus.pending: 0,
    OrderStatus.confirmed: 20,
    OrderStatus.preparing: 60,
    OrderStatus.outForDelivery: 120,
    OrderStatus.delivered: 300,
  };

  /// Advances an order through its lifecycle based on elapsed time.
  Order withLiveStatus(Order order) {
    if (order.status == OrderStatus.cancelled) return order;
    final awaitingPayment =
        order.payment.method.isOnline && order.payment.status != PaymentStatus.paid;

    final elapsed = DateTime.now().difference(order.createdAt).inSeconds;
    final reached = _timeline.entries
        .where((e) => elapsed >= e.value && (!awaitingPayment || e.key == OrderStatus.pending))
        .toList();
    final status = reached.last.key;
    final delivered = status == OrderStatus.delivered;

    final deliveredAt = delivered
        ? order.createdAt.add(Duration(seconds: _timeline[OrderStatus.delivered]!))
        : null;
    return Order(
      id: order.id,
      orderNumber: order.orderNumber,
      status: status,
      createdAt: order.createdAt,
      items: order.items,
      summary: order.summary,
      address: order.address,
      payment: delivered && order.payment.method == PaymentMethod.cod
          ? Payment(
              id: order.payment.id,
              method: order.payment.method,
              status: PaymentStatus.paid,
              amount: order.payment.amount,
              paidAt: deliveredAt,
            )
          : order.payment,
      delivery: Delivery(
        slot: order.delivery.slot,
        estimatedAt: order.delivery.estimatedAt,
        partner: status.step >= OrderStatus.outForDelivery.step ? _partner : null,
        deliveredAt: deliveredAt,
      ),
      statusHistory: [
        for (final e in reached)
          OrderStatusEvent(status: e.key, at: order.createdAt.add(Duration(seconds: e.value))),
      ],
      couponCode: order.couponCode,
      notes: order.notes,
      canCancel: status == OrderStatus.pending || status == OrderStatus.confirmed,
      deliveredAt: deliveredAt,
    );
  }

  String nextOrderNumber() => 'BSK${(100000 + orders.length * 7919 + DateTime.now().second) % 1000000}';

  // ---------------------------------------------------------------- persistence

  Future<void> save() => _cache.writeJson(_stateKey, {
    'users': _users.map((r) => {'user': r.user.toJson(), 'hash': r.passwordHash}).toList(),
    'cart': cartLines,

    'wishlist': wishlist.map((k, v) => MapEntry(k, v.toIso8601String())),
    'addresses': addresses.map((a) => a.toJson()).toList(),
    'orders': orders.map((o) => o.toJson()).toList(),
    'notifications': notifications.map((n) => n.toJson()).toList(),
  });

  void _load() {
    final state = Json.mapOrNull(_cache.readJson(_stateKey));
    if (state == null) return _seed();

    for (final raw in Json.list(state['users'], (j) => j)) {
      _users.add(_UserRecord(User.fromJson(Json.map(raw['user'])), Json.string(raw['hash'])));
    }
    Json.map(state['cart']).forEach((k, v) => cartLines[k] = Json.integer(v));

    Json.map(state['wishlist']).forEach(
      (k, v) => wishlist[k] = Json.date(v) ?? DateTime.now(),
    );
    addresses.addAll(Json.list(state['addresses'], Address.fromJson));
    orders.addAll(Json.list(state['orders'], Order.fromJson));
    notifications.addAll(Json.list(state['notifications'], AppNotification.fromJson));
    if (_users.isEmpty) _seedUser();
  }

  void _seedUser() => addUser(
    User(
      id: 'u1',
      name: 'Aarav Sharma',
      email: 'demo@basketly.app',
      phone: '9876500000',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    'Demo@1234',
  );

  void _seed() {
    _seedUser();
    addresses.addAll(const [
      Address(
        id: 'a1',
        name: 'Home',
        phone: '9876500000',
        fullAddress: 'Flat 402, Green Park Residency, 5th Cross, Indiranagar',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560038',
        isDefault: true,
      ),
      Address(
        id: 'a2',
        name: 'Work',
        phone: '9876500000',
        fullAddress: 'Tower B, 3rd Floor, Prestige Tech Park, Outer Ring Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560103',
      ),
    ]);
    wishlist['p705'] = DateTime.now();
    wishlist['p604'] = DateTime.now();

    Order pastOrder(String id, int daysAgo, List<(String, int)> lines, {bool cancelled = false}) {
      final items = [
        for (final (productId, qty) in lines)
          OrderItem(
            productId: productId,
            name: products[productId]!.name,
            imageUrl: products[productId]!.imageUrl,
            unit: products[productId]!.unit,
            quantity: qty,
            price: products[productId]!.price,
            mrp: products[productId]!.mrp,
          ),
      ];
      final subtotal = items.fold<double>(0, (s, i) => s + i.total);
      final mrp = items.fold<double>(0, (s, i) => s + (i.mrp ?? i.price) * i.quantity);
      final tax = _round(subtotal * taxRate);
      final fee = subtotal >= freeDeliveryThreshold ? 0.0 : deliveryFee;
      final createdAt = DateTime.now().subtract(Duration(days: daysAgo, hours: 3));
      return Order(
        id: id,
        orderNumber: 'BSK${id.hashCode.abs() % 900000 + 100000}',
        status: cancelled ? OrderStatus.cancelled : OrderStatus.pending,
        createdAt: createdAt,
        items: items,
        summary: PriceSummary(
          itemsMrp: mrp,
          productDiscount: _round(mrp - subtotal),
          deliveryFee: fee,
          tax: tax,
          total: _round(subtotal + fee + tax),
        ),
        address: addresses.first,
        payment: Payment(
          method: PaymentMethod.upi,
          status: cancelled ? PaymentStatus.refunded : PaymentStatus.paid,
          amount: _round(subtotal + fee + tax),
          transactionId: 'demo_txn_$id',
        ),
        delivery: Delivery(slot: deliverySlots().first),
        statusHistory: cancelled
            ? [
                OrderStatusEvent(status: OrderStatus.pending, at: createdAt),
                OrderStatusEvent(
                  status: OrderStatus.cancelled,
                  at: createdAt.add(const Duration(minutes: 2)),
                ),
              ]
            : const [],
        canCancel: cancelled ? false : null,
        cancelledAt: cancelled ? createdAt.add(const Duration(minutes: 2)) : null,
      );
    }

    orders.addAll([
      pastOrder('o1003', 3, [('p201', 2), ('p301', 1), ('p202', 1), ('p101', 1)]),
      pastOrder('o1002', 9, [('p501', 1), ('p601', 1), ('p401', 1)]),
      pastOrder('o1001', 18, [('p703', 2), ('p701', 3)], cancelled: true),
    ]);

    final now = DateTime.now();
    notifications.addAll([
      AppNotification(
        id: 'n3',
        title: 'Weekend fruit fest 🍓',
        body: 'Up to 30% off on seasonal fruits. Offer ends Sunday.',
        type: NotificationType.offer,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n2',
        title: 'Order delivered',
        body: 'Your order was delivered. Rate your experience!',
        type: NotificationType.order,
        orderId: 'o1003',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      AppNotification(
        id: 'n1',
        title: 'Welcome to Basketly',
        body: 'Use code WELCOME50 to get 50% off on your first order.',
        type: NotificationType.system,
        createdAt: now.subtract(const Duration(days: 30)),
        isRead: true,
      ),
    ]);
  }
}

class _UserRecord {
  const _UserRecord(this.user, this.passwordHash);

  final User user;
  final String passwordHash;
}
