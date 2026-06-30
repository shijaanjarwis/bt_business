import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/features/reports/domain/history_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TransactionHistoryLabels maps types to register words', () {
    expect(
      TransactionHistoryLabels.forType(TransactionTypes.sale),
      'Bikri',
    );
    expect(
      TransactionHistoryLabels.forType(TransactionTypes.paymentReceived),
      'Jama',
    );
    expect(
      TransactionHistoryLabels.forType(
        TransactionTypes.expense,
        notes: 'Diesel — tank full',
      ),
      'Diesel',
    );
  });

  test('HistoryDateRange resolves today', () {
    final range = HistoryDateRange.resolve(
      period: HistoryPeriod.today,
      now: DateTime(2026, 6, 15),
    );
    expect(range.start, DateTime(2026, 6, 15));
    expect(range.end, DateTime(2026, 6, 15));
  });
}
