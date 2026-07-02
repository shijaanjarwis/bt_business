import 'package:bt_business/data/local/database/migrations/migration_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mirrors [AppDatabase] journal configuration — must use [Database.rawQuery].
Future<void> configureJournalModeLikeApp(Database db) async {
  for (final mode in ['WAL', 'DELETE']) {
    try {
      await db.rawQuery('PRAGMA journal_mode = $mode');
      return;
    } catch (_) {
      // Fall through to DELETE, then default.
    }
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('journal_mode configure via rawQuery succeeds during onConfigure', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 8,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await configureJournalModeLikeApp(db);
        await db.execute('PRAGMA synchronous = NORMAL');
      },
      onCreate: MigrationRunner.onCreate,
      onUpgrade: MigrationRunner.onUpgrade,
    );

    final modeRows = await db.rawQuery('PRAGMA journal_mode');
    expect(modeRows, isNotEmpty);

    await db.close();
  });

  test('v7 migration repair skips existing reminder_date column', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: MigrationRunner.onCreate,
      onUpgrade: MigrationRunner.onUpgrade,
    );

    await MigrationRunner.onUpgrade(db, 6, 7);
    await MigrationRunner.onUpgrade(db, 6, 7);

    final columns = await db.rawQuery('PRAGMA table_info(transactions)');
    final reminderCount = columns
        .where((row) => row['name'] == 'reminder_date')
        .length;
    expect(reminderCount, 1);

    await db.close();
  });
}
