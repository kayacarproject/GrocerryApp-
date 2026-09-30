import 'package:intl/intl.dart';

abstract final class Formatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final NumberFormat _currencyWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// ₹1,249 for whole amounts, ₹1,249.50 otherwise.
  static String currency(num amount) => amount == amount.roundToDouble()
      ? _currencyWhole.format(amount)
      : _currency.format(amount);

  static String date(DateTime date) => DateFormat('d MMM yyyy').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('d MMM yyyy, h:mm a').format(date);

  static String time(DateTime date) => DateFormat('h:mm a').format(date);

  static String compactCount(int count) =>
      NumberFormat.compact(locale: 'en_IN').format(count);

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return Formatters.date(date);
  }

  static String maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${'•' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
  }
}
