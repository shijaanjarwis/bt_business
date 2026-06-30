import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/logger.dart';
import 'database_paths.dart';
import 'migrations/migration_runner.dart';

/// SQLite database access point — offline-first persistence layer.
abstract final class AppDatabase {
  static Database? _instance;
  static const Logger _logger = AppLogger();

  static Future<Database> open() async {
    if (_instance != null) return _instance!;

    try {
      final path = await DatabasePaths.resolve();
      _logger.info('Opening database at $path');

      _instance = await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onConfigure: _onConfigure,
        onCreate: MigrationRunner.onCreate,
        onUpgrade: MigrationRunner.onUpgrade,
      );

      return _instance!;
    } catch (error) {
      throw DatabaseException('Failed to open database: $error');
    }
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
    _logger.info('Database closed');
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }
}
