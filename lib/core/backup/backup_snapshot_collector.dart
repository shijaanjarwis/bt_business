import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../data/local/database/tables/accounting_tables.dart';
import '../accounting/transaction_types.dart';
import 'backup_content_stats.dart';

/// Collects read-only counts from the live database for backup preview.
final class BackupSnapshotCollector {
  const BackupSnapshotCollector(this._database);

  final Database _database;

  Future<BackupContentStats> collect({required String databasePath}) async {
    final dbFile = File(databasePath);
    final databaseSizeBytes =
        await dbFile.exists() ? await dbFile.length() : 0;

    final partyRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${PartiesTable.tableName}',
    );
    final itemRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${ItemsTable.tableName}',
    );
    final saleRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${TransactionsTable.tableName} WHERE ${TransactionsTable.type} = ?',
      [TransactionTypes.sale],
    );
    final purchaseRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${TransactionsTable.tableName} WHERE ${TransactionsTable.type} = ?',
      [TransactionTypes.purchase],
    );
    final expenseRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${TransactionsTable.tableName} WHERE ${TransactionsTable.type} = ?',
      [TransactionTypes.expense],
    );
    final ledgerRows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${JournalLinesTable.tableName}',
    );

    return BackupContentStats(
      databaseSizeBytes: databaseSizeBytes,
      partyCount: partyRows.first['count']! as int,
      itemCount: itemRows.first['count']! as int,
      saleCount: saleRows.first['count']! as int,
      purchaseCount: purchaseRows.first['count']! as int,
      expenseCount: expenseRows.first['count']! as int,
      ledgerEntryCount: ledgerRows.first['count']! as int,
    );
  }
}
