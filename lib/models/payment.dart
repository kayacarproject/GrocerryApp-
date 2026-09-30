import '../core/config/app_config.dart';
import '../core/utils/json_utils.dart';

enum PaymentMethod {
  cod('cod', 'Cash on Delivery'),
  upi('upi', 'UPI'),
  card('card', 'Credit / Debit Card'),
  netBanking('net_banking', 'Net Banking');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isOnline => this != PaymentMethod.cod;

  /// Methods offered to the user right now.
  static List<PaymentMethod> get available =>
      AppConfig.onlinePaymentsEnabled ? values : const [PaymentMethod.cod];

  static PaymentMethod parse(String? value) => PaymentMethod.values.firstWhere(
    (m) => m.apiValue == value,
    orElse: () => PaymentMethod.cod,
  );
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded;

  static PaymentStatus parse(String? value) => PaymentStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => PaymentStatus.pending,
  );
}

class Payment {
  const Payment({
    this.id = '',
    required this.method,
    required this.status,
    required this.amount,
    this.transactionId,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: Json.string(json['id']),
    method: PaymentMethod.parse(Json.stringOrNull(json['method'])),
    status: PaymentStatus.parse(Json.stringOrNull(json['status'])),
    amount: Json.decimal(json['amount']),
    transactionId: Json.stringOrNull(json['gateway_payment_id'] ?? json['transaction_id']),
    paidAt: Json.date(json['paid_at']),
  );

  final String id;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? transactionId;
  final DateTime? paidAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method.apiValue,
    'status': status.name,
    'amount': amount,
    'gateway_payment_id': transactionId,
    'paid_at': paidAt?.toUtc().toIso8601String(),
  };
}

/// A payment created on the server (`/payments/create`) that the gateway
/// SDK then completes.
class PaymentIntent {
  const PaymentIntent({
    required this.paymentId,
    required this.orderId,
    required this.gatewayOrderId,
    required this.amount,
    this.gateway = '',
    this.currency = 'INR',
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    final config = Json.map(json['client_config']);
    return PaymentIntent(
      paymentId: Json.string(json['id']),
      orderId: Json.string(json['order_id']),
      gatewayOrderId: Json.string(json['gateway_order_id']),
      amount: Json.decimal(json['amount']),
      gateway: Json.string(json['gateway']),
      currency: Json.string(config['currency'], 'INR'),
    );
  }

  final String paymentId;
  final String orderId;
  final String gatewayOrderId;
  final double amount;

  /// e.g. `razorpay`, or `mock` on development servers.
  final String gateway;
  final String currency;
}
