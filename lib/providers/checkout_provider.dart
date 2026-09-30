import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../models/delivery.dart';
import '../models/order.dart';
import '../models/payment.dart';
import 'address_provider.dart';
import 'cart_provider.dart';
import 'coupon_provider.dart';
import 'notifications_provider.dart';
import 'orders_provider.dart';
import 'repository_providers.dart';

final deliverySlotsProvider = FutureProvider.autoDispose<List<DeliverySlot>>((ref) {
  final addressId = ref.watch(selectedAddressProvider.select((a) => a?.id));
  if (addressId == null) return const [];
  return ref.read(orderRepositoryProvider).getDeliverySlots(addressId);
});

/// Server-priced bill (delivery, tax, coupon) for the current cart, address
/// and coupon. Re-fetched whenever any of them change.
final checkoutPreviewProvider = FutureProvider.autoDispose<CheckoutPreview?>((ref) async {
  final addressId = ref.watch(selectedAddressProvider.select((a) => a?.id));
  final couponCode = ref.watch(appliedCouponProvider.select((c) => c?.coupon.code));
  final cart = ref.watch(cartProvider).valueOrNull;
  if (addressId == null || cart == null || cart.isEmpty) return null;
  return ref.read(cartRepositoryProvider).preview(addressId: addressId, couponCode: couponCode);
});

class CheckoutState {
  const CheckoutState({
    this.slotId,
    this.paymentMethod =
        AppConfig.onlinePaymentsEnabled ? PaymentMethod.upi : PaymentMethod.cod,
    this.instructions = '',
    this.isPlacingOrder = false,
  });

  final String? slotId;
  final PaymentMethod paymentMethod;
  final String instructions;
  final bool isPlacingOrder;

  CheckoutState copyWith({
    String? slotId,
    PaymentMethod? paymentMethod,
    String? instructions,
    bool? isPlacingOrder,
  }) => CheckoutState(
    slotId: slotId ?? this.slotId,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    instructions: instructions ?? this.instructions,
    isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
  );
}

final checkoutProvider =
    NotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
      CheckoutNotifier.new,
    );

class CheckoutNotifier extends AutoDisposeNotifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void selectSlot(String slotId) => state = state.copyWith(slotId: slotId);

  void selectPayment(PaymentMethod method) =>
      state = state.copyWith(paymentMethod: method);

  void setInstructions(String value) =>
      state = state.copyWith(instructions: value);

  /// Sends references only; the server prices the order from its own data.
  Future<Order> placeOrder() async {
    final address = ref.read(selectedAddressProvider);
    final slots = ref.read(deliverySlotsProvider).valueOrNull ?? const [];
    final slotId =
        state.slotId ?? slots.where((s) => s.isAvailable).firstOrNull?.id;

    if (address == null) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: 'Please add a delivery address.',
      );
    }
    if (slotId == null) {
      throw const ApiException(
        type: ApiErrorType.validation,
        message: 'Please choose a delivery slot.',
      );
    }

    state = state.copyWith(isPlacingOrder: true);
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .placeOrder(
            PlaceOrderRequest(
              addressId: address.id,
              slotId: slotId,
              paymentMethod: state.paymentMethod,
              couponCode: ref.read(appliedCouponProvider)?.coupon.code,
              notes: state.instructions,
            ),
          );
      ref.read(cartProvider.notifier).reload();
      ref.read(appliedCouponProvider.notifier).remove();
      ref.invalidate(ordersProvider);
      ref.invalidate(notificationsProvider);
      return order;
    } finally {
      state = state.copyWith(isPlacingOrder: false);
    }
  }
}
