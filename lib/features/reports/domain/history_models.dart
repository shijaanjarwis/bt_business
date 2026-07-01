import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/utils/register_date_period.dart';

/// Synthetic history row types (not stored in [TransactionsTable.type]).
abstract final class HistoryEntryTypes {
  static const partyCreated = 'party_created';
  static const partyUpdated = 'party_updated';
}

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
      TransactionTypes.paymentPaid => 'Paise Diya',
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
typedef HistoryPeriod = RegisterDatePeriod;

/// Resolves inclusive ISO date bounds for [HistoryPeriod].
abstract final class HistoryDateRange {
  static ({DateTime start, DateTime end}) resolve({
    required HistoryPeriod period,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? now,
  }) =>
      RegisterDateRange.resolve(
        period: period,
        customStart: customStart,
        customEnd: customEnd,
        now: now,
      );
}
