import 'package:intl/intl.dart';

/// Formats amounts in Indian Rupees for dashboard display.
abstract final class CurrencyFormatter {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(double amount) => _inr.format(amount);
}
