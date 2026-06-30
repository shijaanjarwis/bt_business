import '../../../../core/accounting/transaction_types.dart';

/// User-visible label for a register transaction row.
abstract final class TransactionHistoryLabels {
  static String forType(String type, {String? notes}) {
    if (type == TransactionTypes.journal && notes == 'Opening balance') {
      return 'Pehle se baaki';
    }
    return switch (type) {
      TransactionTypes.sale => 'Bikri',
      TransactionTypes.purchase => 'Kharid',
      TransactionTypes.paymentReceived => 'Jama',
      TransactionTypes.paymentPaid => 'Paise Diye',
      TransactionTypes.expense => _expenseLabel(notes),
      _ => 'Entry',
    };
  }

  static String _expenseLabel(String? notes) {
    if (notes == null || notes.trim().isEmpty) return 'Kharch';
    final dash = notes.indexOf(' — ');
    if (dash > 0) return notes.substring(0, dash);
    return notes;
  }
}

/// Filter periods for transaction history.
enum HistoryPeriod {
  today('Aaj', 'Today'),
  thisWeek('Is hafte', 'This Week'),
  thisMonth('Is mahine', 'This Month'),
  thisYear('Is saal', 'This Year'),
  custom('Khud chunein', 'Custom');

  const HistoryPeriod(this.hindiLabel, this.englishLabel);

  final String hindiLabel;
  final String englishLabel;
}

/// Resolves inclusive ISO date bounds for [HistoryPeriod].
abstract final class HistoryDateRange {
  static ({DateTime start, DateTime end}) resolve({
    required HistoryPeriod period,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return switch (period) {
      HistoryPeriod.today => (
          start: todayDate,
          end: todayDate,
        ),
      HistoryPeriod.thisWeek => (
          start: todayDate.subtract(Duration(days: todayDate.weekday - 1)),
          end: todayDate,
        ),
      HistoryPeriod.thisMonth => (
          start: DateTime(todayDate.year, todayDate.month),
          end: todayDate,
        ),
      HistoryPeriod.thisYear => (
          start: DateTime(todayDate.year),
          end: todayDate,
        ),
      HistoryPeriod.custom => (
          start: customStart ?? todayDate,
          end: customEnd ?? todayDate,
        ),
    };
  }
}
