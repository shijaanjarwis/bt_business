import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../business/data/datasources/business_table.dart';
import '../../domain/history_models.dart';

/// A row in the global transaction history register.
class TransactionHistoryEntry {
  const TransactionHistoryEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.amount,
    required this.label,
    required this.partyName,
    this.note,
  });

  final String id;
  final String type;
  final DateTime date;
  final DateTime createdAt;
  final double amount;
  final String label;
  final String? partyName;
  final String? note;
}

final class TransactionHistoryLocalDataSource {
  const TransactionHistoryLocalDataSource(this._db);

  final Database _db;

  Future<List<TransactionHistoryEntry>> fetchHistory({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final businessId = await _currentBusinessId();
      if (businessId == null) return [];

      final startIso = DateFormatter.isoDate(start);
      final endIso = DateFormatter.isoDate(end);

      final rows = await _db.rawQuery(
        '''
        SELECT
          t.${TransactionsTable.id} AS id,
          t.${TransactionsTable.type} AS type,
          t.${TransactionsTable.date} AS date,
          t.${TransactionsTable.createdAt} AS created_at,
          t.${TransactionsTable.totalAmount} AS amount,
          t.${TransactionsTable.notes} AS notes,
          p.${PartiesTable.name} AS party_name
        FROM ${TransactionsTable.tableName} t
        LEFT JOIN ${PartiesTable.tableName} p
          ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
        WHERE t.${TransactionsTable.businessId} = ?
          AND t.${TransactionsTable.date} >= ?
          AND t.${TransactionsTable.date} <= ?
          AND (
            t.${TransactionsTable.type} != ?
            OR t.${TransactionsTable.notes} = 'Opening balance'
          )
        ORDER BY t.${TransactionsTable.date} DESC, t.${TransactionsTable.createdAt} DESC
        ''',
        [businessId, startIso, endIso, TransactionTypes.journal],
      );

      return rows.map((row) {
        final type = row['type']! as String;
        final notes = row['notes'] as String?;
        return TransactionHistoryEntry(
          id: row['id']! as String,
          type: type,
          date: DateTime.parse(row['date']! as String),
          createdAt: DateTime.parse(row['created_at']! as String),
          amount: (row['amount'] as num?)?.toDouble() ?? 0,
          label: TransactionHistoryLabels.forType(type, notes: notes),
          partyName: row['party_name'] as String?,
          note: notes,
        );
      }).toList();
    } catch (error) {
      throw DatabaseException('Failed to load transaction history: $error');
    }
  }

  Future<String?> _currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }
}
