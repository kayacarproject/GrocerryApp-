import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coupon.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'repository_providers.dart';

final availableCouponsProvider = FutureProvider.autoDispose<List<Coupon>>(
  (ref) => ref.watch(cartRepositoryProvider).getCoupons(),
);

final appliedCouponProvider =
    NotifierProvider<AppliedCouponNotifier, CouponValidation?>(
      AppliedCouponNotifier.new,
    );

/// The coupon the user chose. The API applies coupons at checkout, so this is
/// held client-side, validated by the server when applied, and re-checked by
/// the server in checkout preview and when the order is placed.
class AppliedCouponNotifier extends Notifier<CouponValidation?> {
  @override
  CouponValidation? build() {
    ref.watch(currentUserIdProvider);
    return null;
  }

  /// Throws an ApiException with the server's reason when not applicable.
  Future<CouponValidation> apply(String code) async {
    final cartTotal = ref.read(cartProvider).valueOrNull?.displaySubtotal ?? 0;
    final result = await ref
        .read(cartRepositoryProvider)
        .validateCoupon(code.trim().toUpperCase(), cartTotal);
    state = result;
    return result;
  }

  void remove() => state = null;
}
