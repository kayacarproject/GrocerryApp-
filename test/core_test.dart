import 'package:flutter_test/flutter_test.dart';
import 'package:groceryshop/core/network/api_exception.dart';
import 'package:groceryshop/core/utils/formatters.dart';
import 'package:groceryshop/core/utils/validators.dart';
import 'package:groceryshop/models/api_response.dart';
import 'package:groceryshop/models/order.dart';
import 'package:groceryshop/models/product.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('Indian mobile number', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('1234567890'), isNotNull);
      expect(Validators.phone('98765'), isNotNull);
    });

    test('password strength', () {
      expect(Validators.password('abc12345'), isNull);
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
    });

    test('pincode', () {
      expect(Validators.pincode('560038'), isNull);
      expect(Validators.pincode('056003'), isNotNull);
    });
  });

  group('Model parsing is null-safe', () {
    test('Product tolerates missing and string-typed fields', () {
      final product = Product.fromJson({
        'id': 42,
        'name': 'Milk',
        'price': '28.5',
        'image_url': 'https://cdn.example.com/milk.png',
      });
      expect(product.id, '42');
      expect(product.price, 28.5);
      expect(product.mrp, 28.5); // falls back to price
      expect(product.imageUrl, 'https://cdn.example.com/milk.png');
      expect(product.inStock, isFalse);
      expect(product.discountPercent, 0);
    });

    test('Order survives an empty payload', () {
      final order = Order.fromJson(const {});
      expect(order.items, isEmpty);
      expect(order.status, OrderStatus.pending);
    });

    test('OrderStatus parses snake_case', () {
      expect(OrderStatus.parse('out_for_delivery'), OrderStatus.outForDelivery);
      expect(OrderStatus.parse('unknown'), OrderStatus.pending);
    });

    test('ApiResponse reads envelope with pagination', () {
      final response = ApiResponse.fromJson(
        {
          'success': true,
          'data': [1, 2],
          'meta': {'current_page': 1, 'per_page': 2, 'total': 5},
        },
        (data) => (data as List).length,
      );
      expect(response.data, 2);
      expect(response.pagination?.lastPage, 3);
      expect(response.pagination?.hasMore, isTrue);
    });
  });

  group('ApiException', () {
    test('never exposes 5xx server bodies', () {
      final error = ApiException.fromResponse(500, {
        'message': 'NullPointerException at OrderService.java:42',
      });
      expect(error.type, ApiErrorType.server);
      expect(error.message, isNot(contains('Exception')));
    });

    test('keeps short 4xx messages and field errors', () {
      final error = ApiException.fromResponse(422, {
        'message': 'Coupon has expired',
        'errors': {
          'email': ['Email already taken'],
        },
      });
      expect(error.type, ApiErrorType.validation);
      expect(error.message, 'Coupon has expired');
      expect(error.fieldErrors['email'], 'Email already taken');
    });

    test('maps status codes', () {
      expect(ApiException.fromResponse(401, null).type, ApiErrorType.unauthorized);
      expect(ApiException.fromResponse(429, null).type, ApiErrorType.tooManyRequests);
      expect(ApiException.fromResponse(503, null).type, ApiErrorType.serviceUnavailable);
    });
  });

  test('currency formatting', () {
    expect(Formatters.currency(1249), '₹1,249');
    expect(Formatters.currency(49.5), '₹49.50');
  });
}
