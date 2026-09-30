import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../models/product.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/recently_viewed_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/product/add_to_cart_button.dart';
import '../../widgets/product/price_view.dart';
import '../../widgets/product/product_rail.dart';
import '../../widgets/product/wishlist_button.dart';
import 'widgets/image_carousel.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Track views for the "Recently viewed" rail (cached for offline use).
    ref.listenManual(
      productDetailProvider(widget.productId),
      (_, next) => next.whenData(ref.read(recentlyViewedProvider.notifier).add),
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));
    return product.when(
      loading: () => const _LoadingView(),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
      ),
      data: (p) => _DetailsView(product: p),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Skeleton(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            AspectRatio(aspectRatio: 1.1, child: SkeletonBox(radius: AppRadius.xl)),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(height: 12, width: 80),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 22),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 22, width: 200),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(height: 28, width: 120),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(height: 90, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }
}

class _DetailsView extends ConsumerWidget {
  const _DetailsView({required this.product});

  final Product product;

  Future<void> _buyNow(BuildContext context, WidgetRef ref) async {
    try {
      if (ref.read(cartQuantityProvider(product.id)) == 0) {
        await ref.read(cartProvider.notifier).add(product);
      }
      if (context.mounted) context.push(AppRoutes.checkout);
    } catch (error) {
      if (context.mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedProductsProvider(product.id));
    final cartCount = ref.watch(cartCountProvider);
    final imageHeight = (MediaQuery.sizeOf(context).width * 0.95).clamp(260.0, 460.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: imageHeight,
            backgroundColor: AppColors.surface,
            actions: [
              WishlistButton(product: product, size: 20, filledBackground: false),
              IconButton(
                tooltip: 'Cart, $cartCount items',
                onPressed: () => context.go(AppRoutes.cart),
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  backgroundColor: AppColors.accent,
                  textColor: AppColors.textPrimary,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              AppSpacing.gapSm,
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: kToolbarHeight),
                  child: ImageCarousel(product: product),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                _Header(product: product),
                AppSpacing.gapLg,
                _StockAndDelivery(product: product),
                AppSpacing.gapXl,
                if (product.description.isNotEmpty) ...[
                  _SectionTitle('About this product'),
                  _ExpandableText(product.description),
                  AppSpacing.gapXl,
                ],
                if (product.information.isNotEmpty) ...[
                  _SectionTitle('Product information'),
                  _InfoTable(info: product.information),
                  AppSpacing.gapXl,
                ],
                if (product.ingredients != null) ...[
                  _SectionTitle('Ingredients'),
                  Text(
                    product.ingredients!,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  AppSpacing.gapXl,
                ],
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: related.when(
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => ProductRail(title: 'You might also like', products: items),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
      bottomNavigationBar: _BottomActions(
        product: product,
        onBuyNow: () => _buyNow(context, ref),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.brand.isNotEmpty)
          Text(
            product.brand.toUpperCase(),
            style: AppTextStyles.caption.copyWith(color: AppColors.primary, letterSpacing: 0.8),
          ),
        AppSpacing.gapXs,
        Text(product.name, style: AppTextStyles.h2),
        AppSpacing.gapXs,
        Text(product.unit, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        AppSpacing.gapMd,
        RatingBadge(rating: product.rating, reviewCount: product.reviewCount),
        AppSpacing.gapLg,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PriceView(price: product.price, mrp: product.mrp, large: true, axis: Axis.horizontal),
            AppSpacing.gapSm,
            DiscountBadge(percent: product.discountPercent, large: true),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text('MRP inclusive of all taxes', style: AppTextStyles.caption),
      ],
    );
  }
}

class _StockAndDelivery extends ConsumerWidget {
  const _StockAndDelivery({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(selectedAddressProvider);
    final (stockText, stockColor) = !product.inStock
        ? ('Currently out of stock', AppColors.error)
        : product.isLowStock
        ? ('Hurry! Only ${product.stock} left', const Color(0xFFB45309))
        : ('In stock', AppColors.success);

    return AppCard(
      borderColor: AppColors.border,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            iconColor: stockColor,
            title: stockText,
          ),
          const Divider(height: AppSpacing.xl),
          _InfoRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.primary,
            title: 'Delivery in ${product.deliveryMinutes} minutes',
            subtitle: address == null
                ? 'Add an address to check delivery'
                : 'to ${address.name} · ${address.city} ${address.pincode}',
          ),
          const Divider(height: AppSpacing.xl),
          const _InfoRow(
            icon: Icons.verified_outlined,
            iconColor: AppColors.info,
            title: 'Quality checked',
            subtitle: 'Easy returns if you\'re not happy',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label),
              if (subtitle != null) Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(header: true, child: Text(text, style: AppTextStyles.h3)),
  );
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.info});

  final Map<String, String> info;

  @override
  Widget build(BuildContext context) {
    final entries = info.entries.toList();
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Container(
              color: i.isEven ? AppColors.surfaceMuted.withValues(alpha: 0.6) : null,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entries[i].key, style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(entries[i].value, style: AppTextStyles.body),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.product, required this.onBuyNow});

  final Product product;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: AddToCartButton(product: product, large: true),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: AppButton(
                  label: 'Buy now',
                  height: 48,
                  onPressed: product.inStock ? onBuyNow : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
