import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/party_history_builder.dart';
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
      '${PartiesTable.businessId} = ? AND (${PartiesTable.name} LIKE ? OR ${PartiesTable.phone} LIKE ?)',
    );
    final args = <Object?>[businessId, pattern, pattern];
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

  Future<List<PartyHistoryRawRow>> fetchPartyHistory(String partyId) async {
    final party = await fetchParty(partyId);
    if (party == null) return [];

    final rows = await _db.query(
      TransactionsTable.tableName,
      where: '${TransactionsTable.partyId} = ?',
      whereArgs: [partyId],
      orderBy: '${TransactionsTable.date} ASC, ${TransactionsTable.createdAt} ASC',
    );

    return rows.map((row) {
      final type = row[TransactionsTable.type]! as String;
      final notes = row[TransactionsTable.notes] as String?;
      final paymentCode = row[TransactionsTable.paymentMode] as String?;
      final isOpening = type == TransactionTypes.journal && notes == 'Opening balance';

      return PartyHistoryRawRow(
        id: row[TransactionsTable.id]! as String,
        type: type,
        date: DateTime.parse(row[TransactionsTable.date]! as String),
        createdAt: DateTime.parse(row[TransactionsTable.createdAt]! as String),
        totalAmount: (row[TransactionsTable.totalAmount] as num?)?.toDouble() ?? 0,
        paymentMode: paymentCode == null
            ? null
            : PaymentMode.fromCode(paymentCode),
        notes: notes,
        isReceivableOpening: isOpening && party.openingBalance >= 0,
      );
    }).toList();
  }
}
