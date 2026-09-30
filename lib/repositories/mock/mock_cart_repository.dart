import '../../models/cart.dart';
import '../../models/coupon.dart';
import '../../models/order.dart';
import '../cart_repository.dart';
import 'mock_database.dart';

class MockCartRepository implements CartRepository {
  MockCartRepository(this._db);

  static const _maxPerItem = 50;

  final MockDatabase _db;

  @override
  Future<Cart> getCart() async {
    await mockLatency(400);
    return _db.priceCart();
  }

  @override
  Future<Cart> setQuantity(String productId, int quantity) async {
    await mockLatency(300);
    final product = _db.products[productId];
    if (product == null) throw mockError('This product is no longer available.');

    if (quantity <= 0) {
      _db.cartLines.remove(productId);
    } else {
      if (!product.inStock) throw mockError('${product.name} is out of stock.');
      if (quantity > product.stock) {
        throw mockError('Only ${product.stock} left in stock.');
      }
      if (quantity > _maxPerItem) {
        throw mockError('quantity must not be greater than $_maxPerItem');
      }
      _db.cartLines[productId] = quantity;
    }
    await _db.save();
    return _db.priceCart();
  }

  @override
  Future<List<Coupon>> getCoupons() async {
    await mockLatency(400);
    return MockDatabase.coupons;
  }

  @override
  Future<CouponValidation> validateCoupon(String code, double cartTotal) async {
    await mockLatency(500);
    final coupon = _db.couponByCode(code);
    if (coupon == null) throw mockError('This coupon code is not valid');
    if (cartTotal < coupon.minOrderValue) {
      throw mockError(
        'Add items worth ₹${(coupon.minOrderValue - cartTotal).ceil()} more to use ${coupon.code}',
      );
    }
    return CouponValidation(
      coupon: coupon,
      discount: _db.couponDiscountFor(coupon, cartTotal),
      message: 'Coupon applied successfully',
    );
  }

  @override
  Future<CheckoutPreview> preview({required String addressId, String? couponCode}) async {
    await mockLatency(500);
    final address = _db.addresses.where((a) => a.id == addressId).firstOrNull;
    if (address == null) throw mockError('Please select a delivery address.');
    return CheckoutPreview(
      summary: _db.preview(couponCode: couponCode),
      couponCode: couponCode,
      address: address,
    );
  }
}
