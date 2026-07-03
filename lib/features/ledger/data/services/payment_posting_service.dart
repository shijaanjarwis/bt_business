import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/payment_breakdown.dart';
import '../../../../core/accounting/payment_journal_helper.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';

/// Records jama (received) and payment (paid) entries for hisaab.
final class PaymentPostingService {
  const PaymentPostingService(this._db);

  final Database _db;

  Future<String> recordReceived({
    required String businessId,
    required String partyId,
    required double amount,
    required DateTime date,
    String? note,
    String? id,
    DateTime? existingCreatedAt,
    DateTime? reminderDate,
    PaymentBreakdown breakdown = const PaymentBreakdown(),
  }) {
    return _record(
      businessId: businessId,
      partyId: partyId,
      amount: amount,
      date: date,
      note: note,
      type: TransactionTypes.paymentReceived,
      balanceDelta: -amount,
      breakdown: breakdown,
      id: id,
      existingCreatedAt: existingCreatedAt,
      reminderDate: reminderDate,
    );
  }

  Future<String> recordPaid({
    required String businessId,
    required String partyId,
    required double amount,
    required DateTime date,
    String? note,
    String? id,
    DateTime? existingCreatedAt,
    DateTime? reminderDate,
    PaymentBreakdown breakdown = const PaymentBreakdown(),
  }) {
    return _record(
      businessId: businessId,
      partyId: partyId,
      amount: amount,
      date: date,
      note: note,
      type: TransactionTypes.paymentPaid,
      balanceDelta: amount,
      breakdown: breakdown,
      id: id,
      existingCreatedAt: existingCreatedAt,
      reminderDate: reminderDate,
    );
  }

  Future<void> delete(String transactionId) async {
    await _db.transaction((txn) async {
      await _revert(txn, transactionId);
    });
  }

  Future<void> _revert(Transaction txn, String transactionId) async {
    final rows = await txn.query(
      TransactionsTable.tableName,
      where: '${TransactionsTable.id} = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final transaction = rows.first;
    final type = transaction[TransactionsTable.type]! as String;
    final partyId = transaction[TransactionsTable.partyId]! as String;
    final amount = (transaction[TransactionsTable.totalAmount] as num).toDouble();
    final now = DateTime.now().toIso8601String();

    final balanceDelta = switch (type) {
      TransactionTypes.paymentReceived => amount,
      TransactionTypes.paymentPaid => -amount,
      _ => 0.0,
    };

    if (balanceDelta != 0) {
      await txn.rawUpdate(
        '''
        UPDATE ${PartiesTable.tableName}
        SET ${PartiesTable.balance} = ${PartiesTable.balance} + ?,
            ${PartiesTable.updatedAt} = ?
        WHERE ${PartiesTable.id} = ?
        ''',
        [balanceDelta, now, partyId],
      );
    }

    await txn.delete(
      JournalLinesTable.tableName,
      where: '${JournalLinesTable.transactionId} = ?',
      whereArgs: [transactionId],
    );
    await txn.delete(
      TransactionsTable.tableName,
      where: '${TransactionsTable.id} = ?',
      whereArgs: [transactionId],
    );
  }

  Future<String> _record({
    required String businessId,
    required String partyId,
    required double amount,
    required DateTime date,
    String? note,
    required String type,
    required double balanceDelta,
    required PaymentBreakdown breakdown,
    String? id,
    DateTime? existingCreatedAt,
    DateTime? reminderDate,
  }) async {
    if (amount <= 0) {
      throw const ValidationException('Amount must be greater than zero');
    }

    final resolved = breakdown.paidTotal > 0
        ? breakdown.clampToTotal(amount)
        : PaymentBreakdown(cash: amount);
    final paidTotal = resolved.paidTotal;
    if (paidTotal <= 0) {
      throw const ValidationException('Amount must be greater than zero');
    }

    final transactionId = id ?? IdGenerator.newId();
    final now = DateTime.now();
    final isoDate = DateFormatter.isoDate(date);

    await _db.transaction((txn) async {
      if (id != null) {
        await _revert(txn, id);
      }

      await txn.insert(TransactionsTable.tableName, {
        TransactionsTable.id: transactionId,
        TransactionsTable.businessId: businessId,
        TransactionsTable.type: type,
        TransactionsTable.date: isoDate,
        TransactionsTable.partyId: partyId,
        TransactionsTable.notes: note?.trim().isEmpty ?? true ? null : note!.trim(),
        TransactionsTable.totalAmount: paidTotal,
        TransactionsTable.paidAmount: paidTotal,
        TransactionsTable.cashAmount: resolved.cash,
        TransactionsTable.upiAmount: resolved.upi,
        TransactionsTable.bankAmount: resolved.bank,
        TransactionsTable.reminderDate: ReminderService.reminderDateIso(
          ReminderService.effectiveReminderDate(
            transactionType: type,
            dueAmount: 0,
            requestedReminderDate: reminderDate,
          ),
        ),
        TransactionsTable.createdAt: (existingCreatedAt ?? now).toIso8601String(),
        TransactionsTable.updatedAt: now.toIso8601String(),
      });

      if (type == TransactionTypes.paymentReceived) {
        await PaymentJournalHelper.postIncomingBreakdown(
          txn: txn,
          transactionId: transactionId,
          businessId: businessId,
          breakdown: resolved,
          accountId: _accountId,
          insertLine: _insertLine,
        );
        final receivableAccountId =
            await _accountId(txn, businessId, AccountTypes.receivable);
        await _insertLine(
          txn,
          transactionId,
          receivableAccountId,
          partyId: partyId,
          credit: paidTotal,
        );
      } else {
        final payableAccountId =
            await _accountId(txn, businessId, AccountTypes.payable);
        await _insertLine(
          txn,
          transactionId,
          payableAccountId,
          partyId: partyId,
          debit: paidTotal,
        );
        await PaymentJournalHelper.postOutgoingBreakdown(
          txn: txn,
          transactionId: transactionId,
          businessId: businessId,
          breakdown: resolved,
          accountId: _accountId,
          insertLine: _insertLine,
        );
      }

      await txn.rawUpdate(
        '''
        UPDATE ${PartiesTable.tableName}
        SET ${PartiesTable.balance} = ${PartiesTable.balance} + ?,
            ${PartiesTable.updatedAt} = ?
        WHERE ${PartiesTable.id} = ?
        ''',
        [balanceDelta, now.toIso8601String(), partyId],
      );
    });

    return transactionId;
  }

  Future<void> _insertLine(
    Transaction txn,
    String transactionId,
    String accountId, {
    String? partyId,
    double debit = 0,
    double credit = 0,
  }) async {
    await txn.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: accountId,
      JournalLinesTable.partyId: partyId,
      JournalLinesTable.debit: debit,
      JournalLinesTable.credit: credit,
    });
  }

  Future<String> _accountId(
    Transaction txn,
    String businessId,
    String type,
  ) async {
    final rows = await txn.query(
      AccountsTable.tableName,
      columns: [AccountsTable.id],
      where: '${AccountsTable.businessId} = ? AND ${AccountsTable.type} = ?',
      whereArgs: [businessId, type],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Missing $type account for business $businessId');
    }
    return rows.first[AccountsTable.id]! as String;
  }
}
