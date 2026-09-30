import '../core/utils/json_utils.dart';
import 'price_summary.dart';
import 'product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.id = '',
    this.lineTotal,
    this.isAvailable = true,
    this.message,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: Json.string(json['id']),
    product: Product.fromJson(Json.map(json['product'])),
    quantity: Json.integer(json['quantity'], 1),
    lineTotal: Json.decimalOrNull(json['line_total']),
    isAvailable: Json.boolean(json['is_available'], true),
    message: Json.stringOrNull(json['message']),
  );

  /// Server-side cart item id, used to update or remove the line.
  /// Empty while an optimistic add is waiting for the server.
  final String id;
  final Product product;
  final int quantity;

  /// Server-computed line total. Falls back to a display estimate while an
  /// optimistic update is waiting for the server.
  final double? lineTotal;
  final bool isAvailable;

  /// Server note such as "Only 2 left in stock".
  final String? message;

  double get displayTotal => lineTotal ?? product.price * quantity;
  double get displayMrpTotal => product.mrp * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    product: product,
    quantity: quantity ?? this.quantity,
    isAvailable: isAvailable,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product.toJson(),
    'quantity': quantity,
    'line_total': lineTotal,
    'is_available': isAvailable,
    'message': message,
  };
}

class Cart {
  const Cart({this.items = const [], this.summary = PriceSummary.empty});

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    items: Json.list(json['items'], CartItem.fromJson),
    summary: PriceSummary.fromJson(Json.map(json['summary'])),
  );

  static const empty = Cart();

  final List<CartItem> items;

  /// Item totals only; delivery, tax and coupons are priced at checkout.
  final PriceSummary summary;

  bool get isEmpty => items.isEmpty;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  bool get hasUnavailableItems => items.any((i) => !i.isAvailable);

  /// Estimated selling total including optimistic changes.
  double get displaySubtotal => items.fold(0, (sum, i) => sum + i.displayTotal);

  CartItem? itemFor(String productId) {
    for (final item in items) {
      if (item.product.id == productId) return item;
    }
    return null;
  }

  int quantityOf(String productId) => itemFor(productId)?.quantity ?? 0;

  /// Local optimistic change used only until the server responds.
  Cart withQuantity(Product product, int quantity) {
    final next = [...items];
    final index = next.indexWhere((i) => i.product.id == product.id);
    if (quantity <= 0) {
      if (index >= 0) next.removeAt(index);
    } else if (index >= 0) {
      next[index] = next[index].copyWith(quantity: quantity);
    } else {
      next.add(CartItem(product: product, quantity: quantity));
    }
    return Cart(items: next, summary: summary);
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'summary': summary.toJson(),
  };
}
