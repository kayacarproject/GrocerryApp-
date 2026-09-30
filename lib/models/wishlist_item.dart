import '../core/utils/json_utils.dart';
import 'product.dart';

class WishlistItem {
  const WishlistItem({required this.product, this.addedAt});

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
    product: Product.fromJson(Json.map(json['product'])),
    addedAt: Json.date(json['added_at']),
  );

  factory WishlistItem.fromProductJson(Map<String, dynamic> json) =>
      WishlistItem(product: Product.fromJson(json));

  final Product product;
  final DateTime? addedAt;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'added_at': addedAt?.toUtc().toIso8601String(),
  };
}
