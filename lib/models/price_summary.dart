import '../core/utils/json_utils.dart';

/// Bill breakdown. Always computed by the server — the app only renders it.
///
/// API shape: `subtotal` is the MRP total, `discount` the product discount,
/// then `coupon_discount`, `delivery_fee`, `tax` and `total`. The cart
/// endpoint omits delivery and tax; those come from checkout preview.
class PriceSummary {
  const PriceSummary({
    this.itemsMrp = 0,
    this.productDiscount = 0,
    this.couponDiscount = 0,
    this.deliveryFee = 0,
    this.tax = 0,
    this.total = 0,
    this.freeDeliveryThreshold,
    this.includesCharges = true,
  });

  factory PriceSummary.fromJson(Map<String, dynamic> json) => PriceSummary(
    itemsMrp: Json.decimal(json['subtotal']),
    productDiscount: Json.decimal(json['discount']),
    couponDiscount: Json.decimal(json['coupon_discount']),
    deliveryFee: Json.decimal(json['delivery_fee']),
    tax: Json.decimal(json['tax']),
    total: Json.decimal(json['total']),
    freeDeliveryThreshold: Json.decimalOrNull(json['free_delivery_above']),
    includesCharges: json.containsKey('delivery_fee') || json.containsKey('tax'),
  );

  static const empty = PriceSummary(includesCharges: false);

  /// Sum of MRPs before any discount.
  final double itemsMrp;
  final double productDiscount;
  final double couponDiscount;
  final double deliveryFee;
  final double tax;
  final double total;
  final double? freeDeliveryThreshold;

  /// False for cart totals, where delivery and tax are added at checkout.
  final bool includesCharges;

  /// Sum of selling prices.
  double get subtotal => itemsMrp - productDiscount;

  double get totalSavings => productDiscount + couponDiscount;

  double get amountToFreeDelivery {
    final threshold = freeDeliveryThreshold;
    if (threshold == null) return 0;
    return (threshold - subtotal).clamp(0, threshold).toDouble();
  }

  Map<String, dynamic> toJson() => {
    'subtotal': itemsMrp,
    'discount': productDiscount,
    if (includesCharges) ...{
      'coupon_discount': couponDiscount,
      'delivery_fee': deliveryFee,
      'tax': tax,
    },
    'total': total,
    'free_delivery_above': freeDeliveryThreshold,
  };
}
