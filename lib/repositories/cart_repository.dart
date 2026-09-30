import '../models/cart.dart';
import '../models/coupon.dart';
import '../models/order.dart';
import '../services/api/cart_api_service.dart';

abstract interface class CartRepository {
  Future<Cart> getCart();

  /// Sets the quantity for a product; `0` removes it. Returns the re-priced cart.
  Future<Cart> setQuantity(String productId, int quantity);
  Future<List<Coupon>> getCoupons();

  /// Asks the server whether [code] applies to a cart worth [cartTotal].
  Future<CouponValidation> validateCoupon(String code, double cartTotal);

  /// Full bill (delivery, tax, coupon) for delivering the cart to an address.
  Future<CheckoutPreview> preview({required String addressId, String? couponCode});
}

class RemoteCartRepository implements CartRepository {
  RemoteCartRepository(this._api);

  final CartApiService _api;

  /// Latest server cart, used to map product ids to cart item ids.
  Cart _last = Cart.empty;

  Future<Cart> _remember(Future<Cart> request) async => _last = await request;

  @override
  Future<Cart> getCart() => _remember(_api.getCart());

  @override
  Future<Cart> setQuantity(String productId, int quantity) async {
    var item = _last.itemFor(productId);
    if (item == null || item.id.isEmpty) {
      // Refresh in case the cart changed elsewhere (another device).
      item = (await getCart()).itemFor(productId);
    }
    if (item == null) {
      return quantity <= 0 ? _last : _remember(_api.addItem(productId, quantity));
    }
    if (quantity <= 0) return _remember(_api.removeItem(item.id));
    return _remember(_api.updateItem(item.id, quantity));
  }

  @override
  Future<List<Coupon>> getCoupons() => _api.getCoupons();

  @override
  Future<CouponValidation> validateCoupon(String code, double cartTotal) =>
      _api.validateCoupon(code, cartTotal);

  @override
  Future<CheckoutPreview> preview({required String addressId, String? couponCode}) =>
      _api.preview(addressId: addressId, couponCode: couponCode);
}
