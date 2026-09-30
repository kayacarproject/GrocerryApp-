import '../core/utils/json_utils.dart';

class ProductImage {
  const ProductImage({required this.url, this.id = '', this.isPrimary = false});

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    id: Json.string(json['id']),
    url: Json.string(json['url']),
    isPrimary: Json.boolean(json['is_primary']),
  );

  final String id;

  /// An http(s) URL, or `emoji:<glyph>` for bundled demo art.
  final String url;
  final bool isPrimary;

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'is_primary': isPrimary};
}

/// Catalog product. Prices here are for display only; the server
/// recalculates everything when the cart is priced and the order is placed.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.mrp,
    required this.unit,
    this.brand = '',
    this.categoryId = '',
    this.categoryName = '',
    this.description = '',
    this.images = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.stock = 0,
    this.maxOrderQuantity = 10,
    this.information = const {},
    this.ingredients,
    this.deliveryMinutes = 15,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // `images` may be a list of URL strings or of image objects.
    final rawImages = json['images'];
    final images = <ProductImage>[
      if (rawImages is List)
        for (final (i, img) in rawImages.indexed)
          if (img is String && img.isNotEmpty)
            ProductImage(id: '$i', url: img, isPrimary: i == 0)
          else if (img is Map)
            ProductImage.fromJson(Map<String, dynamic>.from(img)),
    ];
    final thumbnail = Json.stringOrNull(json['image'] ?? json['image_url']);
    final category = Json.map(json['category']);
    final price = Json.decimal(json['price']);
    final brand = Json.string(json['brand']);
    final unit = Json.string(json['unit']);
    final categoryName = Json.string(json['category_name'], Json.string(category['name']));
    final information = Json.stringMap(json['information']);
    final stock = Json.integer(json['stock']);

    return Product(
      id: Json.string(json['id']),
      name: Json.string(json['name']),
      brand: brand,
      categoryId: Json.string(json['category_id'], Json.string(category['id'])),
      categoryName: categoryName,
      description: Json.string(json['description']),
      unit: unit,
      price: price,
      mrp: Json.decimal(json['mrp'], price),
      images: images.isEmpty && thumbnail != null
          ? [ProductImage(url: thumbnail, isPrimary: true)]
          : images,
      rating: Json.decimal(json['rating']),
      reviewCount: Json.integer(json['review_count']),
      // Respect an explicit availability flag even if stock is reported.
      stock: Json.boolean(json['in_stock'], true) ? stock : 0,
      maxOrderQuantity: Json.integer(json['max_order_quantity'], 50),
      information: information.isNotEmpty
          ? information
          : {
              if (brand.isNotEmpty) 'Brand': brand,
              if (unit.isNotEmpty) 'Pack size': unit,
              if (categoryName.isNotEmpty) 'Category': categoryName,
            },
      ingredients: Json.stringOrNull(json['ingredients']),
      deliveryMinutes: Json.integer(json['delivery_minutes'], 15),
      createdAt: Json.date(json['created_at']),
    );
  }

  final String id;
  final String name;
  final String brand;
  final String categoryId;
  final String categoryName;
  final String description;

  /// Pack size shown to users, e.g. "500 g" or "1 L".
  final String unit;

  /// Selling price.
  final double price;

  /// Maximum retail price (pre-discount).
  final double mrp;
  final List<ProductImage> images;
  final double rating;
  final int reviewCount;
  final int stock;
  final int maxOrderQuantity;
  final Map<String, String> information;
  final String? ingredients;
  final int deliveryMinutes;
  final DateTime? createdAt;

  String get imageUrl {
    if (images.isEmpty) return '';
    return images.firstWhere((i) => i.isPrimary, orElse: () => images.first).url;
  }

  bool get inStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 5;
  bool get hasDiscount => mrp > price;
  int get discountPercent =>
      hasDiscount ? (((mrp - price) / mrp) * 100).round() : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': {'id': categoryId, 'name': categoryName},
    'description': description,
    'unit': unit,
    'price': price,
    'mrp': mrp,
    'images': images.map((i) => i.toJson()).toList(),
    'rating': rating,
    'review_count': reviewCount,
    'stock': stock,
    'max_order_quantity': maxOrderQuantity,
    'information': information,
    'ingredients': ingredients,
    'delivery_minutes': deliveryMinutes,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
