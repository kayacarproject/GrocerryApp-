import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';
import '../../models/product.dart';
import '../../providers/wishlist_provider.dart';

/// Heart toggle with a small "pop" when a product is saved.
class WishlistButton extends ConsumerStatefulWidget {
  const WishlistButton({
    super.key,
    required this.product,
    this.size = 20,
    this.filledBackground = true,
  });

  final Product product;
  final double size;
  final bool filledBackground;

  @override
  ConsumerState<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends ConsumerState<WishlistButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 55),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    final wasSaved = ref.read(isWishlistedProvider(widget.product.id));
    if (!wasSaved) _controller.forward(from: 0);
    try {
      await ref.read(wishlistProvider.notifier).toggle(widget.product);
    } catch (error) {
      if (mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(isWishlistedProvider(widget.product.id));
    final icon = ScaleTransition(
      scale: _scale,
      child: Icon(
        saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: saved ? AppColors.error : AppColors.textSecondary,
        size: widget.size,
      ),
    );

    return Semantics(
      button: true,
      toggled: saved,
      label: saved ? 'Remove from wishlist' : 'Add to wishlist',
      excludeSemantics: true,
      child: InkResponse(
        onTap: _toggle,
        radius: 24,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: widget.filledBackground
                ? Container(
                    width: widget.size + 12,
                    height: widget.size + 12,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.shadow, blurRadius: 6),
                      ],
                    ),
                    child: Center(child: icon),
                  )
                : icon,
          ),
        ),
      ),
    );
  }
}
