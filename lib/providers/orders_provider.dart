import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../models/order.dart';
import '../models/payment.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'repository_providers.dart';

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return const [];
  final page = await ref.read(orderRepositoryProvider).getOrders();
  return page.items;
});

final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, id) => ref.watch(orderRepositoryProvider).getOrder(id),
);

/// Polls the tracking endpoint while the order is still in progress.
final orderTrackingProvider = StreamProvider.autoDispose.family<Order, String>((
  ref,
  id,
) async* {
  const interval = Duration(seconds: 8);
  final repo = ref.watch(orderRepositoryProvider);
  while (true) {
    final order = await repo.getTracking(id);
    yield order;
    if (!order.status.isActive) break;
    await Future<void>.delayed(interval);
  }
});

final orderActionsProvider = Provider<OrderActions>(OrderActions.new);

class OrderActions {
  const OrderActions(this._ref);

  final Ref _ref;

  /// Creates the payment on the server, completes it in the gateway, then
  /// asks the server to verify the gateway's signature.
  Future<Payment> pay(Order order, {String? upiId, String? bankCode}) async {
    final repo = _ref.read(orderRepositoryProvider);
    final intent = await repo.createPayment(order.id);
    final result = await _ref
        .read(paymentGatewayProvider)
        .pay(
          intent: intent,
          method: order.payment.method,
          upiId: upiId,
          bankCode: bankCode,
        );
    if (!result.isSuccess) {
      throw ApiException(
        type: ApiErrorType.badRequest,
        message: result.errorMessage ?? 'Payment failed. Please try again.',
      );
    }
    final payment = await repo.verifyPayment(
      intent: intent,
      gatewayPaymentId: result.gatewayPaymentId!,
      signature: result.signature!,
    );
    _refresh(order.id);
    return payment;
  }

  Future<Order> cancel(String orderId) async {
    final order = await _ref.read(orderRepositoryProvider).cancelOrder(orderId);
    _refresh(orderId);
    return order;
  }

  bool needsPayment(Order order) =>
      order.payment.method.isOnline &&
      order.payment.status == PaymentStatus.pending &&
      order.status != OrderStatus.cancelled;

  void _refresh(String orderId) {
    _ref.invalidate(ordersProvider);
    _ref.invalidate(orderDetailProvider(orderId));
    _ref.invalidate(orderTrackingProvider(orderId));
  }
}
