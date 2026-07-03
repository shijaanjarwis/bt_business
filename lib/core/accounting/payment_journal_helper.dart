import 'package:sqflite/sqflite.dart';

import 'account_types.dart';
import 'payment_breakdown.dart';
import '../../data/local/database/tables/accounting_tables.dart';

typedef AccountIdResolver = Future<String> Function(
  Transaction txn,
  String businessId,
  String accountType,
);

typedef JournalLineInserter = Future<void> Function(
  Transaction txn,
  String transactionId,
  String accountId, {
  String? partyId,
  double debit,
  double credit,
});

/// Posts split payment journal lines for sales and purchases.
abstract final class PaymentJournalHelper {
  static Future<void> postSaleReceipt({
    required Transaction txn,
    required String transactionId,
    required String businessId,
    required String partyId,
    required PaymentBreakdown breakdown,
    required double dueAmount,
    required AccountIdResolver accountId,
    required JournalLineInserter insertLine,
  }) async {
    await _postIncoming(
      txn: txn,
      transactionId: transactionId,
      businessId: businessId,
      breakdown: breakdown,
      accountId: accountId,
      insertLine: insertLine,
    );

    if (dueAmount <= 0) return;

    final receivableAccountId =
        await accountId(txn, businessId, AccountTypes.receivable);
    await insertLine(
      txn,
      transactionId,
      receivableAccountId,
      partyId: partyId,
      debit: dueAmount,
    );
    await txn.rawUpdate(
      '''
      UPDATE ${PartiesTable.tableName}
      SET ${PartiesTable.balance} = ${PartiesTable.balance} + ?,
          ${PartiesTable.updatedAt} = ?
      WHERE ${PartiesTable.id} = ?
      ''',
      [dueAmount, DateTime.now().toIso8601String(), partyId],
    );
  }

  static Future<void> postPurchasePayment({
    required Transaction txn,
    required String transactionId,
    required String businessId,
    required String partyId,
    required PaymentBreakdown breakdown,
    required double dueAmount,
    required AccountIdResolver accountId,
    required JournalLineInserter insertLine,
  }) async {
    await _postOutgoing(
      txn: txn,
      transactionId: transactionId,
      businessId: businessId,
      breakdown: breakdown,
      accountId: accountId,
      insertLine: insertLine,
    );

    if (dueAmount <= 0) return;

    final payableAccountId =
        await accountId(txn, businessId, AccountTypes.payable);
    await insertLine(
      txn,
      transactionId,
      payableAccountId,
      partyId: partyId,
      credit: dueAmount,
    );
    await txn.rawUpdate(
      '''
      UPDATE ${PartiesTable.tableName}
      SET ${PartiesTable.balance} = ${PartiesTable.balance} - ?,
          ${PartiesTable.updatedAt} = ?
      WHERE ${PartiesTable.id} = ?
      ''',
      [dueAmount, DateTime.now().toIso8601String(), partyId],
    );
  }

  static Future<void> postIncomingBreakdown({
    required Transaction txn,
    required String transactionId,
    required String businessId,
    required PaymentBreakdown breakdown,
    required AccountIdResolver accountId,
    required JournalLineInserter insertLine,
  }) {
    return _postIncoming(
      txn: txn,
      transactionId: transactionId,
      businessId: businessId,
      breakdown: breakdown,
      accountId: accountId,
      insertLine: insertLine,
    );
  }

  static Future<void> postOutgoingBreakdown({
    required Transaction txn,
    required String transactionId,
    required String businessId,
    required PaymentBreakdown breakdown,
    required AccountIdResolver accountId,
    required JournalLineInserter insertLine,
  }) {
    return _postOutgoing(
      txn: txn,
      transactionId: transactionId,
      businessId: businessId,
      breakdown: breakdown,
      accountId: accountId,
      insertLine: insertLine,
    );
  }

  static Future<void> _postIncoming({
    required Transaction txn,
    required String transactionId,
    required String businessId,
    required PaymentBreakdown breakdown,
    required AccountIdResolver accountId,
    required JournalLineInserter insertLine,
  }) async {
    if (breakdown.cash > 0) {
      final cashAccountId = await accountId(txn, businessId, AccountTypes.cash);
      await insertLine(
        txn,
        transactionId,
        cashAccountId,
        debit: breakdown.cash,
      );
    }
    if (breakdown.upi > 0) {
      final upiAccountId = await accountId(txn, businessId, AccountTypes.upi);
      await insertLine(
        txn,
        transactionId,
        upiAccountId,
        debit: breakdown.upi,
      );
    }
    if (breakdown.bank > 0) {
      final bankAccountId = await accountId(txn, businessId, AccountTypes.bank);
      await insertLine(
        txn,
        transactionId,
        bankAccountId,
        debit: breakdown.bank,
      );
    }
    if (breakdown.cheque > 0) {
      final bankAccountId = await accountId(txn, businessId, AccountTypes.bank);
      await insertLine(
        txn,
        transactionId,
        bankAccountId,
        debit: breakdown.cheque,
      );
    }
  }

  static Future<void> _postOutgoing({
    required Transaction txn,
    required String transactionId,
    required String businessId,
    required PaymentBreakdown breakdown,
    required AccountIdResolver accountId,
    required JournalLineInserter insertLine,
  }) async {
    if (breakdown.cash > 0) {
      final cashAccountId = await accountId(txn, businessId, AccountTypes.cash);
      await insertLine(
        txn,
        transactionId,
        cashAccountId,
        credit: breakdown.cash,
      );
    }
    if (breakdown.upi > 0) {
      final upiAccountId = await accountId(txn, businessId, AccountTypes.upi);
      await insertLine(
        txn,
        transactionId,
        upiAccountId,
        credit: breakdown.upi,
      );
    }
    if (breakdown.bank > 0) {
      final bankAccountId = await accountId(txn, businessId, AccountTypes.bank);
      await insertLine(
        txn,
        transactionId,
        bankAccountId,
        credit: breakdown.bank,
      );
    }
    if (breakdown.cheque > 0) {
      final bankAccountId = await accountId(txn, businessId, AccountTypes.bank);
      await insertLine(
        txn,
        transactionId,
        bankAccountId,
        credit: breakdown.cheque,
      );
    }
  }
}
