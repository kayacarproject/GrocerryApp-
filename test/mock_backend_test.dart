import 'package:flutter_test/flutter_test.dart';
import 'package:groceryshop/core/network/api_exception.dart';
import 'package:groceryshop/core/storage/local_cache.dart';
import 'package:groceryshop/models/order.dart';
import 'package:groceryshop/models/payment.dart';
import 'package:groceryshop/repositories/mock/mock_cart_repository.dart';
import 'package:groceryshop/repositories/mock/mock_database.dart';
import 'package:groceryshop/repositories/mock/mock_order_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockDatabase db;
  late MockCartRepository cart;
  late MockOrderRepository orders;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = MockDatabase(LocalCache(await SharedPreferences.getInstance()));
    cart = MockCartRepository(db);
    orders = MockOrderRepository(db);
  });

  group('cart and checkout pricing (server-side rules)', () {
    test('cart totals exclude delivery and tax', () async {
      // Toned Milk: ₹28 × 2 = ₹56
      final result = await cart.setQuantity('p201', 2);
      expect(result.summary.subtotal, 56);
      expect(result.summary.total, 56);
      expect(result.summary.includesCharges, isFalse);
    });

    test('preview adds delivery below the free threshold, and tax', () async {
      await cart.setQuantity('p201', 2);
      final s = (await cart.preview(addressId: 'a1')).summary;
      expect(s.deliveryFee, MockDatabase.deliveryFee);
      expect(s.tax, closeTo(56 * MockDatabase.taxRate, 0.01));
      expect(s.total, closeTo(s.subtotal + s.deliveryFee + s.tax, 0.01));
    });

    test('free delivery once subtotal reaches the threshold', () async {
      await cart.setQuantity('p501', 1); // ₹249 atta
      final s = (await cart.preview(addressId: 'a1')).summary;
      expect(s.deliveryFee, 0);
    });

    test('rejects quantities above available stock', () async {
      // Alphonso Mango has 4 in stock.
      await expectLater(() => cart.setQuantity('p107', 5), throwsA(isA<ApiException>()));
    });

    test('coupon requires minimum order value and is capped', () async {
      await expectLater(() => cart.validateCoupon('WELCOME50', 28), throwsA(isA<ApiException>()));

      final valid = await cart.validateCoupon('welcome50', 427);
      expect(valid.coupon.code, 'WELCOME50');
      expect(valid.discount, 100); // 50% capped at ₹100

      await cart.setQuantity('p402', 1); // ₹399
      final s = (await cart.preview(addressId: 'a1', couponCode: 'WELCOME50')).summary;
      expect(s.couponDiscount, 100);
    });

    test('preview rejects a coupon the cart no longer qualifies for', () async {
      await cart.setQuantity('p201', 1);
      await expectLater(
        () => cart.preview(addressId: 'a1', couponCode: 'SAVE30'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('orders', () {
    test('placing an order uses the preview total and clears the cart', () async {
      await cart.setQuantity('p501', 2);
      final preview = await cart.preview(addressId: 'a1');
      final order = await orders.placeOrder(
        const PlaceOrderRequest(addressId: 'a1', paymentMethod: PaymentMethod.cod),
      );
      expect(order.summary.total, preview.summary.total);
      expect(order.status, OrderStatus.pending);
      expect((await cart.getCart()).isEmpty, isTrue);
    });

    test('empty cart cannot be ordered', () async {
      await expectLater(
        () => orders.placeOrder(
          const PlaceOrderRequest(addressId: 'a1', paymentMethod: PaymentMethod.cod),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('online payment: create, then verify with the gateway signature', () async {
      await cart.setQuantity('p501', 1);
      final order = await orders.placeOrder(
        const PlaceOrderRequest(addressId: 'a1', paymentMethod: PaymentMethod.upi),
      );
      expect(order.payment.status, PaymentStatus.pending);

      final intent = await orders.createPayment(order.id);
      await expectLater(
        () => orders.verifyPayment(intent: intent, gatewayPaymentId: 'x', signature: 'bad'),
        throwsA(isA<ApiException>()),
      );
      final paid = await orders.verifyPayment(
        intent: intent,
        gatewayPaymentId: 'pay_123',
        signature: 'mock_success',
      );
      expect(paid.status, PaymentStatus.paid);
      expect((await orders.getOrder(order.id)).payment.transactionId, 'pay_123');
    });
  });
}
