import '../core/utils/json_utils.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.colorHex,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: Json.string(json['id']),
    name: Json.string(json['name']),
    imageUrl: Json.string(json['image'] ?? json['image_url']),
    colorHex: Json.stringOrNull(json['color']),
    productCount: Json.integer(json['product_count']),
  );

  final String id;
  final String name;

  /// An http(s) URL, or `emoji:<glyph>` for bundled demo art.
  final String imageUrl;
  final String? colorHex;
  final int productCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': imageUrl,
    'color': colorHex,
    'product_count': productCount,
  };
}
