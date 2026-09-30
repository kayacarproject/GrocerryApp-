import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';

/// "ADD" button that morphs into a − qty + stepper once the item is in cart.
class AddToCartButton extends ConsumerWidget {
  const AddToCartButton({super.key, required this.product, this.large = false});

  final Product product;

  /// Full-height variant for detail pages and sticky bars.
  final bool large;

  double get _height => large ? 48 : 34;

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        context.showSnack(ApiException.messageOf(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(cartQuantityProvider(product.id));
    final cart = ref.read(cartProvider.notifier);

    if (!product.inStock) {
      return Container(
        height: _height,
        width: large ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Out of stock',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final limit = product.maxOrderQuantity < product.stock
        ? product.maxOrderQuantity
        : product.stock;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: quantity == 0
          ? _AddButton(
              key: const ValueKey('add'),
              height: _height,
              large: large,
              productName: product.name,
              onTap: () {
                HapticFeedback.lightImpact();
                _run(context, () => cart.add(product));
              },
            )
          : _Stepper(
              key: const ValueKey('stepper'),
              height: _height,
              large: large,
              quantity: quantity,
              productName: product.name,
              onDecrement: () => _run(context, () => cart.decrement(product)),
              onIncrement: () {
                if (quantity >= limit) {
                  context.showSnack('You can add up to $limit of this item.');
                  return;
                }
                HapticFeedback.selectionClick();
                _run(context, () => cart.add(product));
              },
            ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    super.key,
    required this.height,
    required this.large,
    required this.productName,
    required this.onTap,
  });

  final double height;
  final bool large;
  final String productName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add $productName to cart',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smAll,
          child: Container(
            height: height,
            width: large ? double.infinity : null,
            constraints: BoxConstraints(minWidth: large ? 120 : 72),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.smAll,
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            child: Text(
              'ADD',
              style: (large ? AppTextStyles.button : AppTextStyles.label)
                  .copyWith(color: AppColors.primary, letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    super.key,
    required this.height,
    required this.large,
    required this.quantity,
    required this.productName,
    required this.onDecrement,
    required this.onIncrement,
  });

  final double height;
  final bool large;
  final int quantity;
  final String productName;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final textStyle = (large ? AppTextStyles.button : AppTextStyles.label)
        .copyWith(color: Colors.white);
    return Container(
      height: height,
      width: large ? double.infinity : null,
      constraints: BoxConstraints(minWidth: large ? 120 : 72),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            label: 'Remove one $productName',
            onTap: onDecrement,
            large: large,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              style: textStyle,
              semanticsLabel: '$quantity in cart',
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            label: 'Add one more $productName',
            onTap: onIncrement,
            large: large,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.large,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: large ? 44 : 28,
          height: double.infinity,
          child: Icon(icon, color: Colors.white, size: large ? 22 : 18),
        ),
      ),
    );
  }
}
