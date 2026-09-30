import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/cart.dart';
import '../../models/coupon.dart';
import '../../models/order.dart';

/// Every cart mutation returns the full, server-priced cart.
class CartApiService {
  const CartApiService(this._client);

  final ApiClient _client;

  static Cart _cart(Object? data) => Cart.fromJson(Json.map(data));

  Future<Cart> getCart() async =>
      (await _client.get(ApiEndpoints.cart, decoder: _cart)).data;

  /// Adds [quantity] on top of any existing quantity for the product.
  Future<Cart> addItem(String productId, int quantity) async {
    final response = await _client.post(
      ApiEndpoints.cartItems,
      body: {'product_id': Json.id(productId), 'quantity': quantity},
      decoder: _cart,
    );
    return response.data;
  }

  Future<Cart> updateItem(String cartItemId, int quantity) async {
    final response = await _client.put(
      ApiEndpoints.cartItem(cartItemId),
      body: {'quantity': quantity},
      decoder: _cart,
    );
    return response.data;
  }

  Future<Cart> removeItem(String cartItemId) async =>
      (await _client.delete(ApiEndpoints.cartItem(cartItemId), decoder: _cart)).data;

  Future<Cart> clear() async =>
      (await _client.delete(ApiEndpoints.cart, decoder: _cart)).data;

  Future<List<Coupon>> getCoupons() async {
    final response = await _client.get(
      ApiEndpoints.coupons,
      decoder: (data) => Json.list(data, Coupon.fromJson),
    );
    return response.data;
  }

  Future<CouponValidation> validateCoupon(String code, double cartTotal) async {
    final response = await _client.post(
      ApiEndpoints.validateCoupon,
      body: {'code': code, 'cart_total': cartTotal},
      decoder: (data) => CouponValidation.fromJson(Json.map(data)),
    );
    return response.data;
  }

  Future<CheckoutPreview> preview({required String addressId, String? couponCode}) async {
    final response = await _client.post(
      ApiEndpoints.checkoutPreview,
      body: {
        'address_id': Json.id(addressId),
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      },
      decoder: (data) => CheckoutPreview.fromJson(Json.map(data)),
    );
    return response.data;
  }
}
