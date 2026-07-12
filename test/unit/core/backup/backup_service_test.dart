import 'dart:io';

import 'dart:typed_data';

import 'package:bt_business/core/backup/backup_encryption_service.dart';
import 'package:bt_business/core/backup/backup_format.dart';
import 'package:bt_business/core/backup/backup_metadata_store.dart';
import 'package:bt_business/core/backup/backup_packager.dart';
import 'package:bt_business/core/backup/backup_service.dart';
import 'package:bt_business/core/logging/logger.dart';
import 'package:bt_business/data/local/database/app_database.dart';
import 'package:bt_business/data/local/database/migrations/migration_runner.dart';
import 'package:bt_business/data/local/database/tables/accounting_tables.dart';
import 'package:bt_business/data/remote/backup/cloud_backup_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/dashboard_test_data.dart';

class _NoopLogger implements Logger {
  @override
  void debug(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message) {}

  @override
  void warning(String message) {}
}

Future<Database> _openFileTestDatabase(String path) {
  return openDatabase(
    path,
    version: 9,
    singleInstance: false,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: MigrationRunner.onCreate,
    onUpgrade: MigrationRunner.onUpgrade,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('BackupEncryptionService', () {
    test('encrypt and decrypt roundtrip preserves bytes', () async {
      final service = BackupEncryptionService();
      final salt = service.generateSalt();
      const businessId = 'biz-1';
      final plain = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      final encrypted = await service.encrypt(
        plainBytes: plain,
        businessId: businessId,
        saltBase64: salt,
      );
      final decrypted = await service.decrypt(
        encryptedBytes: encrypted,
        businessId: businessId,
        saltBase64: salt,
      );

      expect(decrypted, plain);
    });
  });

  group('BackupService', () {
    late Directory tempDir;
    late Database db;
    late String businessId;
    late BackupService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'assistant_language': 'hi'});
      tempDir = await Directory.systemTemp.createTemp('bt_backup_test');
      final dbPath = p.join(tempDir.path, 'test.db');
      db = await _openFileTestDatabase(dbPath);
      businessId = await seedTestBusiness(db);
      await db.insert(TransactionsTable.tableName, {
        TransactionsTable.id: 'sale-1',
        TransactionsTable.businessId: businessId,
        TransactionsTable.type: 'sale',
        TransactionsTable.date: '2026-07-04',
        TransactionsTable.partyId: await insertCustomer(
          db: db,
          businessId: businessId,
          name: 'Raaj',
        ),
        TransactionsTable.totalAmount: 10000,
        TransactionsTable.paidAmount: 0,
        TransactionsTable.dueAmount: 10000,
        TransactionsTable.createdAt: DateTime.now().toIso8601String(),
        TransactionsTable.updatedAt: DateTime.now().toIso8601String(),
      });

      service = BackupService(
        database: db,
        metadata: BackupMetadataStore.create(),
        cloud: LocalCloudBackupPort(),
        logger: _NoopLogger(),
        backupsDirectoryOverride: Directory(p.join(tempDir.path, 'backups')),
        logosDirectoryOverride: Directory(p.join(tempDir.path, 'logos')),
      );
    });

    tearDown(() async {
      await db.close();
      await AppDatabase.close();
      await tempDir.delete(recursive: true);
    });

    test('create backup and restore returns deleted transaction', () async {
      final dbPath = db.path!;
      final backup = await service.createBackup(type: BackupType.manual);
      expect(File(backup.filePath).existsSync(), isTrue);

      await db.delete(
        TransactionsTable.tableName,
        where: '${TransactionsTable.id} = ?',
        whereArgs: ['sale-1'],
      );

      final rowsBefore = await db.query(TransactionsTable.tableName);
      expect(rowsBefore.where((row) => row[TransactionsTable.id] == 'sale-1'), isEmpty);

      await service.restoreBackup(backup);

      await db.close();
      final restoredDb = await _openFileTestDatabase(dbPath);
      final rowsAfter = await restoredDb.query(TransactionsTable.tableName);
      expect(
        rowsAfter.any((row) => row[TransactionsTable.id] == 'sale-1'),
        isTrue,
      );
      await restoredDb.close();
    });

    test('backup packager reads manifest and database payload', () async {
      final backup = await service.createBackup(type: BackupType.manual);
      final bytes = await File(backup.filePath).readAsBytes();
      final packager = BackupPackager(BackupEncryptionService());
      final bundle = await packager.readEncryptedBackup(fileBytes: bytes);

      expect(bundle.manifest.businessId, businessId);
      expect(bundle.databaseBytes.isNotEmpty, isTrue);
      expect(bundle.preferences.containsKey('assistant_language'), isTrue);
    });

    test('backup manifest includes content stats', () async {
      final backup = await service.createBackup(type: BackupType.manual);
      expect(backup.manifest.stats.partyCount, greaterThanOrEqualTo(1));
      expect(backup.manifest.stats.saleCount, greaterThanOrEqualTo(1));

      final preview = await service.buildCurrentBackupPreview();
      expect(preview.stats.saleCount, greaterThanOrEqualTo(1));
    });

    test('read file preview from backup header', () async {
      final backup = await service.createBackup(type: BackupType.manual);
      final preview = await service.readFilePreview(backup.filePath);
      expect(preview.businessName, isNotEmpty);
      expect(preview.stats.saleCount, greaterThanOrEqualTo(1));
    });
  });
}
