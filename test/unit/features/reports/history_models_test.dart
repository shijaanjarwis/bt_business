import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:bt_business/features/reports/data/datasources/transaction_history_local_datasource.dart';
import 'package:bt_business/features/reports/domain/history_models.dart';
import 'package:bt_business/features/reports/presentation/utils/history_ui_helpers.dart';
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

  test('HistoryUiHelpers groups by date with Aaj and Kal', () {
    final entries = [
      TransactionHistoryEntry(
        id: '1',
        type: TransactionTypes.sale,
        date: DateTime(2026, 6, 15),
        createdAt: DateTime(2026, 6, 15, 10),
        amount: 100,
        label: 'Bikri',
        partyName: 'Ram',
      ),
      TransactionHistoryEntry(
        id: '2',
        type: TransactionTypes.purchase,
        date: DateTime(2026, 6, 14),
        createdAt: DateTime(2026, 6, 14, 9),
        amount: 50,
        label: 'Kharid',
        partyName: 'Shyam',
      ),
    ];

    final grouped = HistoryUiHelpers.groupByDate(
      entries,
      now: DateTime(2026, 6, 15, 12),
    );

    expect(grouped.length, 2);
    expect(grouped.first.header, 'Aaj');
    expect(grouped.last.header, 'Kal');
  });
}
