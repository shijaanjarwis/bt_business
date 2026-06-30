import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/errors/exceptions.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../../../features/business/data/datasources/business_table.dart';
import '../../domain/entities/party.dart';
import '../models/party_model.dart';

/// SQLite read/write operations for ledger parties.
final class PartyLocalDataSource {
  const PartyLocalDataSource(this._db);

  final Database _db;

  Future<String?> currentBusinessId() async {
    final rows = await _db.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first[BusinessTable.id] as String;
  }

  Future<List<Party>> fetchParties({bool activeOnly = false}) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final where = StringBuffer('${PartiesTable.businessId} = ?');
    final args = <Object?>[businessId];
    if (activeOnly) {
      where.write(' AND ${PartiesTable.isActive} = 1');
    }

    final rows = await _db.query(
      PartiesTable.tableName,
      where: where.toString(),
      whereArgs: args,
      orderBy: '${PartiesTable.name} COLLATE NOCASE ASC',
    );

    return rows.map((row) => PartyModel.fromMap(row).toEntity()).toList();
  }

  Future<List<Party>> searchParties(String query, {bool activeOnly = false}) async {
    final businessId = await currentBusinessId();
    if (businessId == null) return [];

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return fetchParties(activeOnly: activeOnly);
    }

    final pattern = '%$trimmed%';
    final where = StringBuffer(
      '${PartiesTable.businessId} = ? AND (${PartiesTable.name} LIKE ? OR ${PartiesTable.phone} LIKE ? OR ${PartiesTable.gstin} LIKE ?)',
    );
    final args = <Object?>[businessId, pattern, pattern, pattern];
    if (activeOnly) {
      where.write(' AND ${PartiesTable.isActive} = 1');
    }

    final rows = await _db.query(
      PartiesTable.tableName,
      where: where.toString(),
      whereArgs: args,
      orderBy: '${PartiesTable.name} COLLATE NOCASE ASC',
    );

    return rows.map((row) => PartyModel.fromMap(row).toEntity()).toList();
  }

  Future<Party?> fetchParty(String id) async {
    final rows = await _db.query(
      PartiesTable.tableName,
      where: '${PartiesTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PartyModel.fromMap(rows.first).toEntity();
  }

  Future<Party> upsertParty(Party party) async {
    await _db.insert(
      PartiesTable.tableName,
      PartyModel(party: party).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return party;
  }

  Future<void> removeParty(String id) async {
    final deleted = await _db.delete(
      PartiesTable.tableName,
      where: '${PartiesTable.id} = ?',
      whereArgs: [id],
    );
    if (deleted == 0) {
      throw DatabaseException('Party not found');
    }
  }

  Future<bool> hasTransactions(String partyId) async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM ${TransactionsTable.tableName}
        WHERE ${TransactionsTable.partyId} = ?
          AND ${TransactionsTable.notes} != 'Opening balance'
        ''',
        [partyId],
      ),
    );
    return (count ?? 0) > 0;
  }
}
