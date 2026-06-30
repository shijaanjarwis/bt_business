import 'package:sqflite/sqflite.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/logger.dart';
import 'migration.dart';
import 'v1_initial.dart';
import 'v2_business.dart';
import 'v3_accounting.dart';
import 'v4_party_ledger.dart';

/// Applies versioned schema migrations on create and upgrade.
abstract final class MigrationRunner {
  static const Logger _logger = AppLogger();

  static final List<Migration> _migrations = [
    V1InitialMigration(),
    V2BusinessMigration(),
    V3AccountingMigration(),
    V4PartyLedgerMigration(),
  ];

  static Future<void> onCreate(Database db, int version) async {
    _logger.info('Creating database schema v$version');
    await _applyThrough(db, version);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    _logger.info('Upgrading database v$oldVersion → v$newVersion');
    for (final migration in _migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        _logger.info('Applying migration v${migration.version}');
        await migration.up(db);
      }
    }
  }

  static Future<void> _applyThrough(Database db, int targetVersion) async {
    for (final migration in _migrations) {
      if (migration.version <= targetVersion) {
        await migration.up(db);
      }
    }
  }
}
