import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';

/// Records kharch entries — reduces cash automatically.
final class ExpensePostingService {
  const ExpensePostingService(this._db);

  final Database _db;

  Future<String> record({
    required String businessId,
    required String name,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    if (amount <= 0) {
      throw const ValidationException('Amount must be greater than zero');
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationException('Kharch ka naam likhiye');
    }

    final transactionId = IdGenerator.newId();
    final now = DateTime.now();
    final isoDate = DateFormatter.isoDate(date);
    final notes = _formatNotes(trimmedName, note);

    await _db.transaction((txn) async {
      await txn.insert(TransactionsTable.tableName, {
        TransactionsTable.id: transactionId,
        TransactionsTable.businessId: businessId,
        TransactionsTable.type: TransactionTypes.expense,
        TransactionsTable.date: isoDate,
        TransactionsTable.notes: notes,
        TransactionsTable.totalAmount: amount,
        TransactionsTable.createdAt: now.toIso8601String(),
        TransactionsTable.updatedAt: now.toIso8601String(),
      });

      final expenseAccountId = await _accountId(txn, businessId, AccountTypes.expense);
      final cashAccountId = await _accountId(txn, businessId, AccountTypes.cash);

      await _insertLine(txn, transactionId, expenseAccountId, debit: amount);
      await _insertLine(txn, transactionId, cashAccountId, credit: amount);
    });

    return transactionId;
  }

  static String _formatNotes(String name, String? note) {
    final trimmedNote = note?.trim();
    if (trimmedNote == null || trimmedNote.isEmpty) return name;
    return '$name — $trimmedNote';
  }

  Future<void> _insertLine(
    Transaction txn,
    String transactionId,
    String accountId, {
    double debit = 0,
    double credit = 0,
  }) async {
    await txn.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: accountId,
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
