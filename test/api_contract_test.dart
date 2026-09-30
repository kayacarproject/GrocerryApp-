// Parses payloads copied from the Postman collection's example responses so
// model changes that break the real API contract fail here first.
import 'package:flutter_test/flutter_test.dart';
import 'package:groceryshop/core/network/api_exception.dart';
import 'package:groceryshop/models/address.dart';
import 'package:groceryshop/models/app_notification.dart';
import 'package:groceryshop/models/auth_session.dart';
import 'package:groceryshop/models/cart.dart';
import 'package:groceryshop/models/coupon.dart';
import 'package:groceryshop/models/order.dart';
import 'package:groceryshop/models/pagination.dart';
import 'package:groceryshop/models/payment.dart';
import 'package:groceryshop/models/product.dart';
import 'package:groceryshop/models/product_query.dart';

const _product = {
  'id': 6,
  'name': 'Amul Taaza Milk',
  'brand': 'Amul',
  'price': 28,
  'mrp': 30,
  'discount_percentage': 7,
  'unit': '500 ml',
  'stock': 75,
  'in_stock': true,
  'rating': 4.5,
  'review_count': 120,
  'category': {'id': 2, 'name': 'Dairy & Eggs'},
  'images': ['https://placehold.co/600x600/png?text=Milk'],
  'is_wishlisted': false,
};

const _address = {
  'id': 22,
  'name': 'Home',
  'full_address': '124 Example Road, Navrangpura',
  'city': 'Ahmedabad',
  'state': 'Gujarat',
  'pincode': '380001',
  'latitude': 23.0225,
  'longitude': 72.5714,
  'phone': '9876543210',
  'is_default': true,
};

void main() {
  test('login response', () {
    final session = AuthSession.fromJson({
      'user': {'id': 2, 'name': 'Priya S.', 'email': 'customer@grocery.test', 'phone': '9000000002'},
      'token': 'TOKEN',
    });
    expect(session.accessToken, 'TOKEN');
    expect(session.user.id, '2');
  });

  test('product with string images and nested category', () {
    final p = Product.fromJson(_product);
    expect(p.id, '6');
    expect(p.imageUrl, contains('placehold.co'));
    expect(p.categoryId, '2');
    expect(p.categoryName, 'Dairy & Eggs');
    expect(p.discountPercent, 7);
    expect(p.inStock, isTrue);
    expect(p.information['Brand'], 'Amul');
  });

  test('paginated list inside data', () {
    final page = PaginatedList.fromData({
      'items': [_product],
      'pagination': {'current_page': 1, 'per_page': 20, 'total': 24, 'last_page': 2},
    }, Product.fromJson);
    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
  });

  test('cart: subtotal is MRP, total is the selling price', () {
    final cart = Cart.fromJson({
      'items': [
        {'id': 41, 'product': _product, 'quantity': 2, 'price': 28, 'mrp': 30, 'line_total': 56, 'is_available': true},
      ],
      'summary': {'item_count': 1, 'total_quantity': 2, 'subtotal': 60, 'discount': 4, 'total': 56},
    });
    expect(cart.items.single.id, '41');
    expect(cart.summary.itemsMrp, 60);
    expect(cart.summary.productDiscount, 4);
    expect(cart.summary.subtotal, 56);
    expect(cart.summary.includesCharges, isFalse);
  });

  test('checkout preview', () {
    final preview = CheckoutPreview.fromJson({
      'subtotal': 380,
      'discount': 51,
      'coupon_discount': 50,
      'delivery_fee': 30,
      'tax': 13.95,
      'total': 322.95,
      'coupon_code': 'WELCOME50',
      'free_delivery_above': 499,
      'address': _address,
    });
    expect(preview.summary.total, 322.95);
    expect(preview.summary.includesCharges, isTrue);
    expect(preview.summary.freeDeliveryThreshold, 499);
    expect(preview.address?.name, 'Home');
  });

  test('order', () {
    final order = Order.fromJson({
      'id': 23,
      'order_number': 'ORD20260929972691',
      'status': 'ready_for_delivery',
      'payment_method': 'cod',
      'payment_status': 'pending',
      'subtotal': 380,
      'discount': 51,
      'coupon_discount': 50,
      'delivery_fee': 30,
      'tax': 13.95,
      'total': 322.95,
      'shipping_address': _address,
      'items': [
        {'id': 33, 'product_id': 6, 'product_name': 'Amul Taaza Milk', 'unit': '500 ml', 'price': 28, 'mrp': 30, 'quantity': 3, 'total': 84},
      ],
      'payment': {'id': 23, 'method': 'cod', 'status': 'pending', 'amount': 322.95},
      'can_cancel': true,
      'created_at': '2026-09-29T11:39:47.404Z',
    });
    expect(order.status, OrderStatus.preparing);
    expect(order.items.single.name, 'Amul Taaza Milk');
    expect(order.items.single.total, 84);
    expect(order.address.fullAddress, startsWith('124'));
    expect(order.payment.method, PaymentMethod.cod);
    expect(order.isCancellable, isTrue);
    expect(order.summary.total, 322.95);
  });

  test('order request sends numeric ids and only allowed fields', () {
    final body = const PlaceOrderRequest(
      addressId: '22',
      paymentMethod: PaymentMethod.upi,
      slotId: 'asap',
      notes: '  ',
    ).toJson();
    expect(body, {'address_id': 22, 'payment_method': 'upi'});
  });

  test('address request body excludes id and default flag', () {
    final body = Address.fromJson(_address).toRequestJson();
    expect(body.containsKey('id'), isFalse);
    expect(body.containsKey('is_default'), isFalse);
    expect(body['full_address'], startsWith('124'));
  });

  test('coupon and payment intent', () {
    final coupon = Coupon.fromJson({
      'code': 'WELCOME50',
      'type': 'fixed',
      'value': 50,
      'min_order_amount': 300,
    });
    expect(coupon.discountType, DiscountType.flat);
    expect(coupon.isApplicableFor(299), isFalse);

    final intent = PaymentIntent.fromJson({
      'id': 24,
      'order_id': 24,
      'gateway_order_id': 'mock_order_x',
      'amount': 287.25,
      'client_config': {'currency': 'INR'},
    });
    expect(intent.paymentId, '24');
    expect(intent.gatewayOrderId, 'mock_order_x');
  });

  test('notification type and order link', () {
    final n = AppNotification.fromJson({
      'id': 97,
      'type': 'order_delivered',
      'title': 'Order delivered',
      'body': 'Delivered',
      'data': {'order_id': 23},
      'is_read': false,
      'created_at': '2026-09-29T11:42:31.290Z',
    });
    expect(n.type, NotificationType.order);
    expect(n.orderId, '23');
  });

  test('query uses API sort names and single brand', () {
    final q = const ProductQuery(
      sort: ProductSort.priceLowToHigh,
      filter: ProductFilter(brands: {'Amul'}, minRating: 4, minDiscount: 10),
    ).toQueryParameters();
    expect(q['sort'], 'price_low');
    expect(q['brand'], 'Amul');
    expect(q['rating'], 4);
    expect(q.containsKey('min_discount'), isFalse);
  });

  test('wrong password shows the server message, expired token does not', () {
    final wrong = ApiException.fromResponse(401, {
      'success': false,
      'message': 'Invalid credentials',
      'code': 'INVALID_CREDENTIALS',
    });
    expect(wrong.message, 'Invalid credentials');

    final expired = ApiException.fromResponse(401, {'message': 'Unauthenticated', 'code': 'UNAUTHENTICATED'});
    expect(expired.message, contains('session'));
  });
}
