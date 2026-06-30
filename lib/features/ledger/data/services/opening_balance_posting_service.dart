import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../domain/entities/party.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;

/// Posts double-entry journal records for party opening balances.
final class OpeningBalancePostingService {
  const OpeningBalancePostingService(this._db);

  final Database _db;

  Future<String?> post({
    required String businessId,
    required Party party,
    required double signedOpeningBalance,
    String? existingTransactionId,
  }) async {
    if (signedOpeningBalance == 0) {
      if (existingTransactionId != null) {
        await _deleteTransaction(existingTransactionId);
      }
      return null;
    }

    if (existingTransactionId != null) {
      await _deleteTransaction(existingTransactionId);
    }

    final receivableAccountId = await _accountId(businessId, AccountTypes.receivable);
    final payableAccountId = await _accountId(businessId, AccountTypes.payable);
    final equityAccountId = await _accountId(businessId, AccountTypes.equity);

    final transactionId = IdGenerator.newId();
    final now = DateTime.now();
    final amount = signedOpeningBalance.abs();
    final isReceivable = signedOpeningBalance > 0;

    await _db.transaction((txn) async {
      await txn.insert(TransactionsTable.tableName, {
        TransactionsTable.id: transactionId,
        TransactionsTable.businessId: businessId,
        TransactionsTable.type: TransactionTypes.journal,
        TransactionsTable.date: DateFormatter.isoDate(now),
        TransactionsTable.partyId: party.id,
        TransactionsTable.notes: 'Opening balance',
        TransactionsTable.totalAmount: amount,
        TransactionsTable.createdAt: now.toIso8601String(),
        TransactionsTable.updatedAt: now.toIso8601String(),
      });

      if (isReceivable) {
        await _insertLine(txn, transactionId, receivableAccountId, party.id, debit: amount);
        await _insertLine(txn, transactionId, equityAccountId, null, credit: amount);
      } else {
        await _insertLine(txn, transactionId, equityAccountId, null, debit: amount);
        await _insertLine(txn, transactionId, payableAccountId, party.id, credit: amount);
      }
    });

    return transactionId;
  }

  Future<void> deleteOpeningTransaction(String transactionId) async {
    await _deleteTransaction(transactionId);
  }

  Future<void> _deleteTransaction(String transactionId) async {
    await _db.transaction((txn) async {
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
    });
  }

  Future<void> _insertLine(
    Transaction txn,
    String transactionId,
    String accountId,
    String? partyId, {
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

  Future<String> _accountId(String businessId, String type) async {
    final rows = await _db.query(
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
