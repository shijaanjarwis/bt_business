import 'package:bt_business/features/ledger/domain/entities/party_history_builder.dart';
import 'package:bt_business/features/ledger/domain/entities/party_history_entry.dart';
import 'package:bt_business/core/accounting/payment_modes.dart';
import 'package:bt_business/core/accounting/transaction_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds running balance in date order', () {
    final rows = [
      PartyHistoryRawRow(
        id: '1',
        type: TransactionTypes.sale,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1, 10),
        totalAmount: 250,
        paymentMode: PaymentMode.credit,
        notes: null,
        isReceivableOpening: false,
      ),
      PartyHistoryRawRow(
        id: '2',
        type: TransactionTypes.paymentReceived,
        date: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2, 10),
        totalAmount: 100,
        paymentMode: null,
        notes: null,
        isReceivableOpening: false,
      ),
      PartyHistoryRawRow(
        id: '3',
        type: TransactionTypes.sale,
        date: DateTime(2026, 1, 3),
        createdAt: DateTime(2026, 1, 3, 10),
        totalAmount: 500,
        paymentMode: PaymentMode.credit,
        notes: null,
        isReceivableOpening: false,
      ),
      PartyHistoryRawRow(
        id: '4',
        type: TransactionTypes.purchase,
        date: DateTime(2026, 1, 4),
        createdAt: DateTime(2026, 1, 4, 10),
        totalAmount: 200,
        paymentMode: PaymentMode.credit,
        notes: null,
        isReceivableOpening: false,
      ),
      PartyHistoryRawRow(
        id: '5',
        type: TransactionTypes.paymentPaid,
        date: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 5, 10),
        totalAmount: 200,
        paymentMode: null,
        notes: null,
        isReceivableOpening: false,
      ),
    ];

    final entries = PartyHistoryBuilder.build(rows);

    expect(entries, hasLength(5));
    expect(entries[0].label, 'Bikri');
    expect(entries[0].runningBalance, 250);
    expect(entries[1].label, 'Jama');
    expect(entries[1].runningBalance, 150);
    expect(entries[2].runningBalance, 650);
    expect(entries[3].runningBalance, 450);
    expect(entries[4].runningBalance, 650);
  });

  test('cash sale does not change running balance', () {
    final rows = [
      PartyHistoryRawRow(
        id: '1',
        type: TransactionTypes.sale,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        totalAmount: 500,
        paymentMode: PaymentMode.cash,
        notes: null,
        isReceivableOpening: false,
      ),
    ];

    final entries = PartyHistoryBuilder.build(rows);
    expect(entries.single.runningBalance, 0);
    expect(entries.single.kind, PartyHistoryKind.sale);
  });

  test('opening balance sets initial running balance', () {
    final rows = [
      PartyHistoryRawRow(
        id: '1',
        type: TransactionTypes.journal,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        totalAmount: 1000,
        paymentMode: null,
        notes: 'Opening balance',
        isReceivableOpening: true,
      ),
    ];

    final entries = PartyHistoryBuilder.build(rows);
    expect(entries.single.label, 'Pehle se baaki');
    expect(entries.single.runningBalance, 1000);
  });
}
