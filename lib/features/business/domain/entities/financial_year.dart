import 'package:intl/intl.dart';

/// Helpers for Indian financial year configuration.
abstract final class FinancialYear {
  static const int defaultStartMonth = 4;

  static const List<int> startMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  static String labelForStartMonth(int month) {
    final monthName = DateFormat('MMMM').format(DateTime(2024, month));
    if (month == defaultStartMonth) {
      return '$monthName (Indian FY)';
    }
    return monthName;
  }

  static String rangeLabel(int startMonth) {
    final start = DateFormat('MMM').format(DateTime(2024, startMonth));
    final endMonth = startMonth == 1 ? 12 : startMonth - 1;
    final end = DateFormat('MMM').format(DateTime(2024, endMonth));
    return '$start – $end';
  }
}
