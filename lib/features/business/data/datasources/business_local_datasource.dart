import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/business.dart';
import '../models/business_model.dart';
import 'business_table.dart';

/// SQLite read/write operations for the business profile.
final class BusinessLocalDataSource {
  const BusinessLocalDataSource(this._db);

  final Database _db;

  Future<Business?> fetchBusiness() async {
    try {
      final rows = await _db.query(
        BusinessTable.tableName,
        limit: 1,
      );

      if (rows.isEmpty) return null;
      return BusinessModel.fromMap(rows.first).toEntity();
    } catch (error) {
      throw DatabaseException('Failed to read business profile: $error');
    }
  }

  Future<Business> upsertBusiness(Business business) async {
    try {
      await _db.insert(
        BusinessTable.tableName,
        BusinessModel(business: business).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return business;
    } catch (error) {
      throw DatabaseException('Failed to save business profile: $error');
    }
  }

  Future<void> removeBusiness(String id) async {
    try {
      final deleted = await _db.delete(
        BusinessTable.tableName,
        where: '${BusinessTable.id} = ?',
        whereArgs: [id],
      );

      if (deleted == 0) {
        throw DatabaseException('Business profile not found');
      }
    } catch (error) {
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete business profile: $error');
    }
  }

  Future<bool> exists() async {
    try {
      final count = Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM ${BusinessTable.tableName}',
        ),
      );
      return (count ?? 0) > 0;
    } catch (error) {
      throw DatabaseException('Failed to check business profile: $error');
    }
  }
}
