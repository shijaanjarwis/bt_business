import 'dart:io';

import 'package:path/path.dart' as p;
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
      await _ensureDatabaseDirectory(path);
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

  static Future<void> _ensureDatabaseDirectory(String path) async {
    final directory = Directory(p.dirname(path));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _configureJournalMode(db);
    await _configureSynchronous(db);
  }

  /// sqflite_darwin rejects [Database.execute] for PRAGMA journal_mode because
  /// it returns rows ("not an error"). Use [Database.rawQuery] and never crash
  /// bootstrap if WAL is unavailable on device storage.
  static Future<void> _configureJournalMode(Database db) async {
    for (final mode in ['WAL', 'DELETE']) {
      try {
        final result = await db.rawQuery('PRAGMA journal_mode = $mode');
        final applied = result.isNotEmpty
            ? result.first.values.first?.toString().toLowerCase()
            : null;
        _logger.info('Database journal mode set to ${applied ?? mode}');
        return;
      } catch (error) {
        _logger.warning('Could not set journal mode $mode: $error');
      }
    }

    _logger.warning('Continuing with SQLite default journal mode');
  }

  static Future<void> _configureSynchronous(Database db) async {
    try {
      await db.execute('PRAGMA synchronous = NORMAL');
    } catch (error) {
      _logger.warning('Could not set synchronous mode: $error');
    }
  }
}
