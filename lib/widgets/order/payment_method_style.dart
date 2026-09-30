import 'package:flutter/material.dart';

import '../../models/payment.dart';

extension PaymentMethodStyle on PaymentMethod {
  IconData get icon => switch (this) {
    PaymentMethod.cod => Icons.payments_outlined,
    PaymentMethod.upi => Icons.qr_code_2_rounded,
    PaymentMethod.card => Icons.credit_card_rounded,
    PaymentMethod.netBanking => Icons.account_balance_outlined,
  };

  String get hint => switch (this) {
    PaymentMethod.cod => 'Pay with cash or UPI when your order arrives',
    PaymentMethod.upi => 'Pay instantly using any UPI app',
    PaymentMethod.card => 'Visa, Mastercard, RuPay and more',
    PaymentMethod.netBanking => 'All major banks supported',
  };
}

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.pending => 'Payment pending',
    PaymentStatus.paid => 'Paid',
    PaymentStatus.failed => 'Payment failed',
    PaymentStatus.refunded => 'Refunded',
  };
}
