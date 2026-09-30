import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/coupon.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/skeletons.dart';

/// Shows the applied coupon, or an entry point to browse and apply one.
class CouponSection extends ConsumerWidget {
  const CouponSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = ref.watch(appliedCouponProvider);
    final coupon = applied?.coupon;

    if (applied != null && coupon != null) {
      return AppCard(
        borderColor: AppColors.primarySoft,
        color: AppColors.primaryLight,
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded, color: AppColors.primary),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${coupon.code} applied', style: AppTextStyles.title),
                  Text(
                    'You save ${Formatters.currency(applied.discount)} on this order',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: ref.read(appliedCouponProvider.notifier).remove,
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: () => showCouponSheet(context),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: AppColors.primary),
          AppSpacing.gapMd,
          Expanded(child: Text('Apply Coupon', style: AppTextStyles.title)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

Future<void> showCouponSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _CouponSheet(),
);

class _CouponSheet extends ConsumerStatefulWidget {
  const _CouponSheet();

  @override
  ConsumerState<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends ConsumerState<_CouponSheet> {
  final _codeController = TextEditingController();
  String? _applyingCode;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _apply(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = 'Enter a coupon code');
      return;
    }
    setState(() {
      _applyingCode = trimmed.toUpperCase();
      _error = null;
    });
    try {
      await ref.read(appliedCouponProvider.notifier).apply(trimmed);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.showSnack('Coupon ${trimmed.toUpperCase()} applied 🎉');
    } catch (error) {
      if (mounted) setState(() => _error = ApiException.messageOf(error));
    } finally {
      if (mounted) setState(() => _applyingCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupons = ref.watch(availableCouponsProvider);
    final cartTotal = ref.watch(cartProvider.select((c) => c.valueOrNull?.displaySubtotal ?? 0));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.screen,
              child: Text('Apply coupon', style: AppTextStyles.h2),
            ),
            AppSpacing.gapLg,
            Padding(
              padding: AppSpacing.screen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _apply,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        errorText: _error,
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  AppButton(
                    label: 'Apply',
                    expand: false,
                    isLoading: _applyingCode != null &&
                        _applyingCode == _codeController.text.trim().toUpperCase(),
                    onPressed: () => _apply(_codeController.text),
                  ),
                ],
              ),
            ),
            AppSpacing.gapLg,
            Padding(
              padding: AppSpacing.screen,
              child: Text('Available coupons', style: AppTextStyles.title),
            ),
            AppSpacing.gapSm,
            Flexible(
              child: coupons.when(
                loading: () => const ListSkeleton(count: 3, item: TileSkeleton()),
                error: (error, _) => Padding(
                  padding: AppSpacing.screen,
                  child: Text(ApiException.messageOf(error), style: AppTextStyles.bodySmall),
                ),
                data: (list) => ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => AppSpacing.gapMd,
                  itemBuilder: (_, index) => _CouponTile(
                    coupon: list[index],
                    cartTotal: cartTotal,
                    isApplying: _applyingCode == list[index].code,
                    onApply: () => _apply(list[index].code),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.coupon,
    required this.cartTotal,
    required this.isApplying,
    required this.onApply,
  });

  final Coupon coupon;
  final double cartTotal;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    // Hint only: the server validates when the coupon is applied.
    final enabled = coupon.isApplicableFor(cartTotal);
    final shortfall = coupon.minOrderValue - cartTotal;
    return AppCard(
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: enabled ? AppColors.accentLight : AppColors.surfaceMuted,
                  borderRadius: AppRadius.xsAll,
                  border: Border.all(
                    color: enabled ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Text(
                  coupon.code,
                  style: AppTextStyles.label.copyWith(letterSpacing: 1),
                ),
              ),
              const Spacer(),
              isApplying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: enabled ? onApply : null,
                      child: const Text('APPLY'),
                    ),
            ],
          ),
          AppSpacing.gapSm,
          Text(coupon.title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xxs),
          if (coupon.description.isNotEmpty)
            Text(coupon.description, style: AppTextStyles.bodySmall),
          if (!enabled) ...[
            AppSpacing.gapXs,
            Text(
              'Add ${Formatters.currency(shortfall.ceil())} more to unlock',
              style: AppTextStyles.caption.copyWith(color: const Color(0xFFB45309)),
            ),
          ],
        ],
      ),
    );
  }
}
