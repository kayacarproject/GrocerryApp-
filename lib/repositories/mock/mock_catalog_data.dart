// Demo catalog used only when AppConfig.useMockData is true.
// Brands are fictional. Imagery uses the `emoji:` scheme understood by
// AppImage, so the demo works fully offline.

import '../../models/category.dart';
import '../../models/home_feed.dart';
import '../../models/product.dart';

const mockCategories = <Category>[
  Category(id: 'c1', name: 'Fruits & Vegetables', imageUrl: 'emoji:🥦', colorHex: '#E3F4E8'),
  Category(id: 'c2', name: 'Dairy & Eggs', imageUrl: 'emoji:🥛', colorHex: '#E6EFFC'),
  Category(id: 'c3', name: 'Bakery', imageUrl: 'emoji:🥐', colorHex: '#FFF0E0'),
  Category(id: 'c4', name: 'Rice & Grains', imageUrl: 'emoji:🍚', colorHex: '#F4EEE6'),
  Category(id: 'c5', name: 'Atta & Flour', imageUrl: 'emoji:🌾', colorHex: '#FFF7D9'),
  Category(id: 'c6', name: 'Oil & Ghee', imageUrl: 'emoji:🌻', colorHex: '#FFF3D6'),
  Category(id: 'c7', name: 'Snacks', imageUrl: 'emoji:🍿', colorHex: '#FDE9EA'),
  Category(id: 'c8', name: 'Beverages', imageUrl: 'emoji:🧃', colorHex: '#E2F5F4'),
  Category(id: 'c9', name: 'Personal Care', imageUrl: 'emoji:🧴', colorHex: '#F0EAFB'),
  Category(id: 'c10', name: 'Household', imageUrl: 'emoji:💡', colorHex: '#E9F0FA'),
  Category(id: 'c11', name: 'Cleaning', imageUrl: 'emoji:🧽', colorHex: '#E4F6F1'),
  Category(id: 'c12', name: 'Baby Care', imageUrl: 'emoji:🍼', colorHex: '#FCEBF1'),
  Category(id: 'c13', name: 'Frozen Food', imageUrl: 'emoji:🍨', colorHex: '#E5F1FB'),
  Category(id: 'c14', name: 'Meat & Seafood', imageUrl: 'emoji:🍗', colorHex: '#FBE9E4'),
  Category(id: 'c15', name: 'Pet Supplies', imageUrl: 'emoji:🐾', colorHex: '#F7EFE3'),
];

class _Seed {
  const _Seed(
    this.id,
    this.categoryId,
    this.name,
    this.brand,
    this.unit,
    this.emoji,
    this.price,
    this.mrp, {
    this.rating = 4.3,
    this.reviews = 120,
    this.stock = 40,
    this.ingredients,
    this.daysOld = 60,
  });

  final String id;
  final String categoryId;
  final String name;
  final String brand;
  final String unit;
  final String emoji;
  final double price;
  final double mrp;
  final double rating;
  final int reviews;
  final int stock;
  final String? ingredients;
  final int daysOld;
}

const _seeds = <_Seed>[
  // Fruits & Vegetables
  _Seed('p101', 'c1', 'Banana Robusta', 'Basketly Fresh', '6 pcs (approx. 1 kg)', '🍌', 49, 62, rating: 4.5, reviews: 2140),
  _Seed('p102', 'c1', 'Shimla Red Apple', 'Basketly Fresh', '4 pcs (approx. 600 g)', '🍎', 139, 180, rating: 4.4, reviews: 1320),
  _Seed('p103', 'c1', 'Fresh Tomato', 'Basketly Fresh', '500 g', '🍅', 24, 32, rating: 4.2, reviews: 3010),
  _Seed('p104', 'c1', 'Onion', 'Basketly Fresh', '1 kg', '🧅', 38, 50, rating: 4.3, reviews: 2890),
  _Seed('p105', 'c1', 'Potato', 'Basketly Fresh', '1 kg', '🥔', 32, 40, rating: 4.4, reviews: 2560),
  _Seed('p106', 'c1', 'Broccoli', 'GreenLeaf Farms', '1 pc (approx. 250 g)', '🥦', 59, 79, rating: 4.1, reviews: 410),
  _Seed('p107', 'c1', 'Alphonso Mango', 'GreenLeaf Farms', '1 kg', '🥭', 299, 399, rating: 4.7, reviews: 860, stock: 4),
  _Seed('p108', 'c1', 'Orange Carrot', 'Basketly Fresh', '500 g', '🥕', 29, 38, rating: 4.2, reviews: 740),
  // Dairy & Eggs
  _Seed('p201', 'c2', 'Toned Milk', 'Dairy Dale', '500 ml', '🥛', 28, 28, rating: 4.6, reviews: 5120, daysOld: 400),
  _Seed('p202', 'c2', 'Farm Fresh Eggs', "Nature's Nest", '12 pcs', '🥚', 89, 105, rating: 4.5, reviews: 1980),
  _Seed('p203', 'c2', 'Salted Butter', 'Dairy Dale', '100 g', '🧈', 58, 60, rating: 4.7, reviews: 2210),
  _Seed('p204', 'c2', 'Fresh Malai Paneer', 'Dairy Dale', '200 g', '🧀', 85, 99, rating: 4.4, reviews: 1430),
  _Seed('p205', 'c2', 'Greek Yogurt Blueberry', 'Cultured Co.', '400 g', '🥣', 119, 150, rating: 4.3, reviews: 320, daysOld: 5),
  _Seed('p206', 'c2', 'Cheddar Cheese Slices', 'Cultured Co.', '200 g (10 slices)', '🧀', 135, 150, rating: 4.4, reviews: 690),
  // Bakery
  _Seed('p301', 'c3', 'Whole Wheat Bread', 'Bake House', '400 g', '🍞', 45, 50, rating: 4.3, reviews: 1760, ingredients: 'Whole wheat flour, water, yeast, sugar, edible vegetable oil, salt, preservative (282).'),
  _Seed('p302', 'c3', 'Butter Croissant', 'Bake House', '2 pcs', '🥐', 79, 99, rating: 4.5, reviews: 540, ingredients: 'Refined wheat flour, butter (24%), sugar, yeast, milk solids, salt.'),
  _Seed('p303', 'c3', 'Chocolate Chip Muffin', 'Bake House', '2 pcs', '🧁', 69, 90, rating: 4.2, reviews: 380),
  _Seed('p304', 'c3', 'Multigrain Bagels', 'Oven Crest', '4 pcs', '🥯', 99, 125, rating: 4.1, reviews: 150, daysOld: 3),
  _Seed('p305', 'c3', 'French Baguette', 'Oven Crest', '1 pc (250 g)', '🥖', 65, 80, rating: 4.0, reviews: 90, stock: 0),
  // Rice & Grains
  _Seed('p401', 'c4', 'Premium Basmati Rice', 'Royal Grain', '1 kg', '🍚', 159, 210, rating: 4.6, reviews: 2470),
  _Seed('p402', 'c4', 'Sona Masoori Rice', 'Royal Grain', '5 kg', '🍚', 399, 480, rating: 4.4, reviews: 1320),
  _Seed('p403', 'c4', 'Brown Rice', 'Royal Grain', '1 kg', '🍚', 139, 170, rating: 4.2, reviews: 430),
  _Seed('p404', 'c4', 'White Quinoa', 'Nutri Harvest', '500 g', '🌾', 249, 330, rating: 4.3, reviews: 260),
  _Seed('p405', 'c4', 'Thick Poha', 'Nutri Harvest', '500 g', '🍚', 45, 55, rating: 4.2, reviews: 610),
  // Atta & Flour
  _Seed('p501', 'c5', 'Whole Wheat Atta', 'Golden Harvest', '5 kg', '🌾', 249, 299, rating: 4.6, reviews: 3890),
  _Seed('p502', 'c5', 'Multigrain Atta', 'Golden Harvest', '1 kg', '🌾', 89, 110, rating: 4.3, reviews: 720),
  _Seed('p503', 'c5', 'Besan (Gram Flour)', 'Golden Harvest', '500 g', '🌾', 65, 80, rating: 4.4, reviews: 980),
  _Seed('p504', 'c5', 'Maida (Refined Flour)', 'Golden Harvest', '1 kg', '🌾', 52, 60, rating: 4.2, reviews: 540),
  _Seed('p505', 'c5', 'Ragi Flour', 'Nutri Harvest', '500 g', '🌾', 69, 85, rating: 4.3, reviews: 330),
  // Oil & Ghee
  _Seed('p601', 'c6', 'Refined Sunflower Oil', 'Sun Valley', '1 L', '🌻', 155, 185, rating: 4.4, reviews: 2150),
  _Seed('p602', 'c6', 'Pure Cow Ghee', 'Dairy Dale', '500 ml', '🧈', 329, 375, rating: 4.7, reviews: 1840),
  _Seed('p603', 'c6', 'Kachi Ghani Mustard Oil', 'Sun Valley', '1 L', '🌼', 179, 215, rating: 4.3, reviews: 870),
  _Seed('p604', 'c6', 'Extra Virgin Olive Oil', 'Medi Gold', '500 ml', '🌿', 549, 699, rating: 4.5, reviews: 410),
  _Seed('p605', 'c6', 'Cold Pressed Groundnut Oil', 'Sun Valley', '1 L', '🥜', 210, 260, rating: 4.4, reviews: 520),
  // Snacks
  _Seed('p701', 'c7', 'Classic Salted Chips', 'Crunchy Co.', '90 g', '🍟', 20, 20, rating: 4.3, reviews: 4210),
  _Seed('p702', 'c7', 'Butter Popcorn', 'Crunchy Co.', '60 g', '🍿', 35, 40, rating: 4.2, reviews: 980),
  _Seed('p703', 'c7', 'Double Choco Cookies', 'Crumbs & Co.', '150 g', '🍪', 45, 60, rating: 4.5, reviews: 1740),
  _Seed('p704', 'c7', 'Roasted Almonds', 'Nutri Harvest', '200 g', '🥜', 219, 299, rating: 4.6, reviews: 1230),
  _Seed('p705', 'c7', '70% Dark Chocolate', 'Cocoa Craft', '100 g', '🍫', 99, 125, rating: 4.6, reviews: 860, daysOld: 7),
  _Seed('p706', 'c7', 'Cheese Nachos', 'Crunchy Co.', '150 g', '🌮', 65, 85, rating: 4.1, reviews: 470),
  // Beverages
  _Seed('p801', 'c8', 'Orange Juice, No Added Sugar', 'Sip & Co.', '1 L', '🧃', 115, 140, rating: 4.3, reviews: 1120),
  _Seed('p802', 'c8', 'Classic Cold Coffee', 'Brew Bros', '200 ml', '☕', 45, 50, rating: 4.4, reviews: 660),
  _Seed('p803', 'c8', 'Tulsi Green Tea', 'Leaf & Cup', '25 tea bags', '🍵', 149, 199, rating: 4.5, reviews: 1430),
  _Seed('p804', 'c8', 'Tender Coconut Water', 'Sip & Co.', '200 ml', '🥥', 40, 50, rating: 4.2, reviews: 540),
  _Seed('p805', 'c8', 'Sparkling Lemonade', 'Fizzio', '300 ml', '🍋', 35, 40, rating: 4.0, reviews: 310, daysOld: 2),
  // Personal Care
  _Seed('p901', 'c9', 'Aloe Vera Face Wash', 'PureGlow', '100 ml', '🧴', 145, 199, rating: 4.3, reviews: 1870),
  _Seed('p902', 'c9', 'Herbal Anti-Dandruff Shampoo', 'PureGlow', '340 ml', '🧴', 225, 299, rating: 4.2, reviews: 1320),
  _Seed('p903', 'c9', 'Fresh Mint Toothpaste', 'BrightSmile', '150 g', '🦷', 89, 99, rating: 4.4, reviews: 2440),
  _Seed('p904', 'c9', 'Sandal Bath Soap', 'PureGlow', 'Pack of 4 (100 g each)', '🧼', 149, 180, rating: 4.3, reviews: 990),
  _Seed('p905', 'c9', 'Cocoa Body Lotion', 'PureGlow', '400 ml', '🧴', 249, 349, rating: 4.4, reviews: 760),
  // Household
  _Seed('p1001', 'c10', 'Kitchen Paper Towels', 'HomeMate', '2 rolls', '🧻', 99, 120, rating: 4.2, reviews: 430),
  _Seed('p1002', 'c10', 'Garbage Bags (Medium)', 'HomeMate', '30 bags', '🗑️', 89, 110, rating: 4.1, reviews: 610),
  _Seed('p1003', 'c10', 'LED Bulb 9W', 'Lumina', '1 pc', '💡', 99, 150, rating: 4.5, reviews: 880),
  _Seed('p1004', 'c10', 'Alkaline AA Batteries', 'Lumina', '4 pcs', '🔋', 120, 140, rating: 4.4, reviews: 540),
  _Seed('p1005', 'c10', 'Lavender Scented Candles', 'HomeMate', '2 pcs', '🕯️', 199, 260, rating: 4.3, reviews: 180, daysOld: 10),
  // Cleaning
  _Seed('p1101', 'c11', 'Lemon Dishwash Liquid', 'Sparkle', '750 ml', '🧽', 115, 135, rating: 4.5, reviews: 2130),
  _Seed('p1102', 'c11', 'Floral Floor Cleaner', 'Sparkle', '1 L', '🧹', 179, 215, rating: 4.4, reviews: 1290),
  _Seed('p1103', 'c11', 'Matic Detergent Powder', 'Sparkle', '1 kg', '🧺', 129, 155, rating: 4.3, reviews: 1650),
  _Seed('p1104', 'c11', 'Streak-free Glass Cleaner', 'Sparkle', '500 ml', '✨', 99, 125, rating: 4.2, reviews: 420),
  _Seed('p1105', 'c11', 'Toilet Cleaner', 'Sparkle', '500 ml', '🚽', 89, 105, rating: 4.3, reviews: 870),
  // Baby Care
  _Seed('p1201', 'c12', 'Baby Diaper Pants (M)', 'TinyToes', '30 pcs', '👶', 499, 699, rating: 4.6, reviews: 1540),
  _Seed('p1202', 'c12', 'Gentle Baby Wipes', 'TinyToes', '72 wipes', '🧻', 149, 199, rating: 4.5, reviews: 1120),
  _Seed('p1203', 'c12', 'Baby Moisturising Lotion', 'TinyToes', '200 ml', '🍼', 179, 225, rating: 4.4, reviews: 640),
  _Seed('p1204', 'c12', 'Rice & Apple Baby Cereal', 'TinyToes', '300 g', '🥣', 229, 265, rating: 4.3, reviews: 380),
  // Frozen Food
  _Seed('p1301', 'c13', 'Frozen Green Peas', 'FrostBite', '500 g', '🌱', 99, 125, rating: 4.2, reviews: 720),
  _Seed('p1302', 'c13', 'Madagascar Vanilla Ice Cream', 'FrostBite', '700 ml', '🍨', 199, 260, rating: 4.6, reviews: 1480),
  _Seed('p1303', 'c13', 'Margherita Frozen Pizza', 'FrostBite', '1 pc (7 inch)', '🍕', 179, 225, rating: 4.1, reviews: 390),
  _Seed('p1304', 'c13', 'Crispy French Fries', 'FrostBite', '400 g', '🍟', 119, 150, rating: 4.3, reviews: 860),
  _Seed('p1305', 'c13', 'Chicken Nuggets', 'FrostBite', '400 g', '🍗', 229, 280, rating: 4.4, reviews: 540, stock: 3),
  // Meat & Seafood
  _Seed('p1401', 'c14', 'Chicken Breast Boneless', 'FreshCut', '500 g', '🍗', 229, 290, rating: 4.4, reviews: 1320),
  _Seed('p1402', 'c14', 'Rohu Fish Curry Cut', 'FreshCut', '500 g', '🐟', 199, 245, rating: 4.2, reviews: 480),
  _Seed('p1403', 'c14', 'Medium Prawns (Cleaned)', 'FreshCut', '250 g', '🦐', 299, 365, rating: 4.3, reviews: 350),
  _Seed('p1404', 'c14', 'Mutton Curry Cut', 'FreshCut', '500 g', '🥩', 449, 520, rating: 4.5, reviews: 610, stock: 0),
  // Pet Supplies
  _Seed('p1501', 'c15', 'Adult Dog Food, Chicken', 'Happy Paws', '1.2 kg', '🐕', 399, 480, rating: 4.5, reviews: 720),
  _Seed('p1502', 'c15', 'Tuna Cat Food', 'Happy Paws', '400 g', '🐈', 249, 299, rating: 4.4, reviews: 410),
  _Seed('p1503', 'c15', 'Gentle Pet Shampoo', 'Happy Paws', '200 ml', '🐾', 199, 260, rating: 4.2, reviews: 190),
  _Seed('p1504', 'c15', 'Rubber Chew Bone', 'Happy Paws', '1 pc', '🦴', 149, 199, rating: 4.3, reviews: 260),
];

const _storageByCategory = <String, (String shelfLife, String storage)>{
  'c1': ('3–5 days', 'Store in a cool, dry place or refrigerate'),
  'c2': ('2–7 days', 'Keep refrigerated below 4°C'),
  'c3': ('3 days', 'Store in a cool, dry place'),
  'c13': ('6 months', 'Keep frozen at -18°C or below'),
  'c14': ('2 days', 'Keep refrigerated below 4°C'),
};

Product _build(_Seed s) {
  final category = mockCategories.firstWhere((c) => c.id == s.categoryId);
  final (shelfLife, storage) =
      _storageByCategory[s.categoryId] ?? ('12 months', 'Store in a cool, dry place');
  final image = 'emoji:${s.emoji}';
  return Product(
    id: s.id,
    name: s.name,
    brand: s.brand,
    categoryId: s.categoryId,
    categoryName: category.name,
    unit: s.unit,
    price: s.price,
    mrp: s.mrp,
    images: [
      ProductImage(id: '${s.id}-1', url: image, isPrimary: true),
      ProductImage(id: '${s.id}-2', url: image),
      ProductImage(id: '${s.id}-3', url: image),
    ],
    rating: s.rating,
    reviewCount: s.reviews,
    stock: s.stock,
    maxOrderQuantity: s.stock == 0 ? 0 : (s.stock < 10 ? s.stock : 10),
    description:
        '${s.name} from ${s.brand}, hand-picked and quality checked at our '
        'partner store so it reaches you fresh. Carefully packed to keep it '
        'safe in transit and delivered to your door in minutes.',
    information: {
      'Brand': s.brand,
      'Pack size': s.unit,
      'Shelf life': shelfLife,
      'Storage': storage,
      'Country of origin': 'India',
      'FSSAI licence': '1002XXXXXXXXXX',
    },
    ingredients: s.ingredients,
    deliveryMinutes: 12,
    createdAt: DateTime.now().subtract(Duration(days: s.daysOld)),
  );
}

final List<Product> mockProducts = _seeds.map(_build).toList(growable: false);

const mockBanners = <PromoBanner>[
  PromoBanner(
    id: 'b1',
    title: 'Farm-fresh fruits\nup to 30% off',
    subtitle: 'Picked this morning',
    imageUrl: 'emoji:🍓',
    categoryId: 'c1',
    colorHex: '#0E7C4A',
  ),
  PromoBanner(
    id: 'b2',
    title: 'Breakfast essentials\nfrom ₹28',
    subtitle: 'Milk, eggs, bread & more',
    imageUrl: 'emoji:🥞',
    categoryId: 'c2',
    colorHex: '#2D5BD0',
  ),
  PromoBanner(
    id: 'b3',
    title: 'Snack time?\nBuy more, save more',
    subtitle: 'Chips, cookies & chocolates',
    imageUrl: 'emoji:🍫',
    categoryId: 'c7',
    colorHex: '#C2410C',
  ),
  PromoBanner(
    id: 'b4',
    title: 'Free delivery\non orders above ₹199',
    subtitle: 'No code needed',
    imageUrl: 'emoji:🛵',
    colorHex: '#7C3AED',
    ctaLabel: 'Start shopping',
  ),
];

const mockPopularSearches = <String>[
  'Milk',
  'Bread',
  'Eggs',
  'Banana',
  'Chips',
  'Paneer',
  'Atta',
  'Ice cream',
];
