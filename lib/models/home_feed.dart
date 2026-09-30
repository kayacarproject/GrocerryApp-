import '../core/utils/json_utils.dart';
import 'product.dart';

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.ctaLabel = 'Shop now',
    this.categoryId,
    this.colorHex,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: Json.string(json['id']),
    title: Json.string(json['title']),
    subtitle: Json.string(json['subtitle']),
    imageUrl: Json.string(json['image_url']),
    ctaLabel: Json.string(json['cta_label'], 'Shop now'),
    categoryId: Json.stringOrNull(json['category_id']),
    colorHex: Json.stringOrNull(json['color']),
  );

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String ctaLabel;

  /// Category opened when the banner is tapped.
  final String? categoryId;
  final String? colorHex;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'image_url': imageUrl,
    'cta_label': ctaLabel,
    'category_id': categoryId,
    'color': colorHex,
  };
}

/// A titled product rail on the home screen ("Best sellers", "Deals"...).
class ProductSection {
  const ProductSection({
    required this.key,
    required this.title,
    required this.products,
    this.subtitle,
  });

  factory ProductSection.fromJson(Map<String, dynamic> json) => ProductSection(
    key: Json.string(json['key']),
    title: Json.string(json['title']),
    subtitle: Json.stringOrNull(json['subtitle']),
    products: Json.list(json['products'], Product.fromJson),
  );

  final String key;
  final String title;
  final String? subtitle;
  final List<Product> products;

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'subtitle': subtitle,
    'products': products.map((p) => p.toJson()).toList(),
  };
}

class HomeFeed {
  const HomeFeed({required this.banners, required this.sections});

  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(
    banners: Json.list(json['banners'], PromoBanner.fromJson),
    sections: Json.list(json['sections'], ProductSection.fromJson),
  );

  final List<PromoBanner> banners;
  final List<ProductSection> sections;

  Map<String, dynamic> toJson() => {
    'banners': banners.map((b) => b.toJson()).toList(),
    'sections': sections.map((s) => s.toJson()).toList(),
  };
}
