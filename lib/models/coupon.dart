import '../core/utils/formatters.dart';
import '../core/utils/json_utils.dart';

enum DiscountType { percentage, flat }

class Coupon {
  const Coupon({
    required this.code,
    required this.discountType,
    required this.value,
    this.id = '',
    this.description = '',
    this.maxDiscount,
    this.minOrderValue = 0,
    this.expiresAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    final type = Json.string(json['type'] ?? json['discount_type']);
    return Coupon(
      id: Json.string(json['id']),
      code: Json.string(json['code']),
      description: Json.string(json['description']),
      discountType: (type == 'fixed' || type == 'flat')
          ? DiscountType.flat
          : DiscountType.percentage,
      value: Json.decimal(json['value']),
      maxDiscount: Json.decimalOrNull(json['max_discount']),
      minOrderValue: Json.decimal(json['min_order_amount'] ?? json['min_order_value']),
      expiresAt: Json.date(json['expires_at']),
    );
  }

  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double value;
  final double? maxDiscount;
  final double minOrderValue;
  final DateTime? expiresAt;

  /// Short headline, e.g. "10% OFF" or "FLAT ₹50 OFF".
  String get title => discountType == DiscountType.flat
      ? 'Flat ${Formatters.currency(value)} off'
      : '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}% off'
            '${maxDiscount == null ? '' : ' up to ${Formatters.currency(maxDiscount!)}'}';

  /// Display hint only; the server decides eligibility.
  bool isApplicableFor(double cartTotal) => cartTotal >= minOrderValue;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'description': description,
    'type': discountType == DiscountType.flat ? 'fixed' : 'percentage',
    'value': value,
    'max_discount': maxDiscount,
    'min_order_amount': minOrderValue,
    'expires_at': expiresAt?.toUtc().toIso8601String(),
  };
}

/// Server response to validating a coupon against the current cart.
class CouponValidation {
  const CouponValidation({
    required this.coupon,
    required this.discount,
    this.message,
  });

  factory CouponValidation.fromJson(Map<String, dynamic> json) => CouponValidation(
    coupon: Coupon.fromJson(Json.map(json['coupon'])),
    discount: Json.decimal(json['discount']),
    message: Json.stringOrNull(json['message']),
  );

  final Coupon coupon;
  final double discount;
  final String? message;
}
