import '../models/payment.dart';

class PaymentResult {
  const PaymentResult.success({required this.gatewayPaymentId, required this.signature})
    : errorMessage = null;
  const PaymentResult.failure(this.errorMessage)
    : gatewayPaymentId = null,
      signature = null;

  final String? gatewayPaymentId;

  /// Gateway signature the server checks in `/payments/verify`.
  final String? signature;
  final String? errorMessage;

  bool get isSuccess => gatewayPaymentId != null && signature != null;
}

/// Abstraction over a payment provider's SDK (Razorpay, Stripe, PayU...).
///
/// Card numbers, UPI PINs and bank credentials are entered inside the
/// provider's own secure UI — they never pass through this app or our API.
abstract interface class PaymentGateway {
  Future<PaymentResult> pay({
    required PaymentIntent intent,
    required PaymentMethod method,
    String? upiId,
    String? bankCode,
  });
}

/// Stand-in for the backend's `mock` gateway: it approves every payment and
/// returns the signature the development server accepts.
class DemoPaymentGateway implements PaymentGateway {
  const DemoPaymentGateway();

  @override
  Future<PaymentResult> pay({
    required PaymentIntent intent,
    required PaymentMethod method,
    String? upiId,
    String? bankCode,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return PaymentResult.success(
      gatewayPaymentId: 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      signature: 'mock_success',
    );
  }
}
