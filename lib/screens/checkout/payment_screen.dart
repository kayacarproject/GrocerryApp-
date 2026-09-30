import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/order/payment_method_style.dart';
import 'widgets/checkout_section.dart';

/// Collects the non-sensitive choice (UPI app / bank) and hands off to the
/// payment gateway. Card numbers and PINs are only ever entered in the
/// gateway's own secure UI.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _banks = ['SBI', 'HDFC Bank', 'ICICI Bank', 'Axis Bank', 'Kotak', 'Other banks'];

  final _upiId = TextEditingController();
  String? _bank;
  bool _paying = false;

  @override
  void dispose() {
    _upiId.dispose();
    super.dispose();
  }

  Future<void> _pay(Order order) async {
    final method = order.payment.method;
    if (method == PaymentMethod.netBanking && _bank == null) {
      context.showSnack('Please choose your bank', isError: true);
      return;
    }
    final upi = _upiId.text.trim();
    if (method == PaymentMethod.upi && upi.isNotEmpty && !RegExp(r'^[\w.-]+@[\w]+$').hasMatch(upi)) {
      context.showSnack('Enter a valid UPI ID, e.g. name@bank', isError: true);
      return;
    }
    context.unfocus();
    setState(() => _paying = true);
    try {
      await ref.read(orderActionsProvider).pay(
        order,
        upiId: upi.isEmpty ? null : upi,
        bankCode: _bank,
      );
      if (mounted) context.go(AppRoutes.orderSuccess(order.id));
    } catch (error) {
      if (mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: order.when(
        loading: () => const ListSkeleton(count: 2, item: TileSkeleton()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              color: AppColors.primary,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount to pay',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                        ),
                        Text(
                          Formatters.currency(order.summary.total),
                          style: AppTextStyles.h1.copyWith(color: Colors.white),
                        ),
                        Text(
                          'Order #${order.orderNumber}',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(order.payment.method.icon, color: Colors.white, size: 40),
                ],
              ),
            ),
            AppSpacing.gapXl,
            ..._methodContent(order.payment.method),
            AppSpacing.gapXl,
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textTertiary),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    'Payments are processed securely by our payment partner. '
                    'We never see or store your card details or PIN.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: order.valueOrNull == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton(
                  label: 'Pay ${Formatters.currency(order.valueOrNull!.summary.total)}',
                  icon: Icons.lock_rounded,
                  isLoading: _paying,
                  onPressed: () => _pay(order.valueOrNull!),
                ),
              ),
            ),
    );
  }

  List<Widget> _methodContent(PaymentMethod method) => switch (method) {
    PaymentMethod.upi => [
      Text('Pay using UPI', style: AppTextStyles.title),
      AppSpacing.gapSm,
      Text(
        'Tap pay to choose any UPI app on your phone, or enter your UPI ID.',
        style: AppTextStyles.bodySmall,
      ),
      AppSpacing.gapLg,
      TextField(
        controller: _upiId,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'yourname@bank (optional)',
          prefixIcon: Icon(Icons.alternate_email_rounded),
        ),
      ),
    ],
    PaymentMethod.netBanking => [
      Text('Choose your bank', style: AppTextStyles.title),
      AppSpacing.gapMd,
      for (final bank in _banks) ...[
        SelectableTile(
          title: bank,
          icon: Icons.account_balance_outlined,
          selected: _bank == bank,
          onTap: () => setState(() => _bank = bank),
        ),
        AppSpacing.gapSm,
      ],
    ],
    PaymentMethod.card => [
      Text('Credit / Debit card', style: AppTextStyles.title),
      AppSpacing.gapSm,
      Text(
        'You\'ll enter your card details on our partner\'s secure payment page.',
        style: AppTextStyles.bodySmall,
      ),
    ],
    PaymentMethod.cod => [
      Text('Cash on delivery', style: AppTextStyles.title),
    ],
  };
}
