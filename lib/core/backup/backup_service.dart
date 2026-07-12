import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database/app_database.dart';
import '../../data/local/database/database_paths.dart';
import '../../data/remote/backup/cloud_backup_port.dart';
import '../../features/business/data/datasources/business_table.dart';
import '../constants/app_constants.dart';
import '../logging/logger.dart';
import 'backup_encryption_service.dart';
import 'backup_format.dart';
import 'backup_metadata_store.dart';
import 'backup_packager.dart';

/// Creates, restores, exports, and prunes encrypted business backups.
final class BackupService {
  BackupService({
    required Database database,
    required BackupMetadataStore metadata,
    required CloudBackupPort cloud,
    required Logger logger,
    BackupEncryptionService? encryption,
    BackupPackager? packager,
    Connectivity? connectivity,
    Directory? backupsDirectoryOverride,
    Directory? logosDirectoryOverride,
  })  : _database = database,
        _metadata = metadata,
        _cloud = cloud,
        _logger = logger,
        _encryption = encryption ?? BackupEncryptionService(),
        _packager = packager ?? BackupPackager(encryption ?? BackupEncryptionService()),
        _connectivity = connectivity ?? Connectivity(),
        _backupsDirectoryOverride = backupsDirectoryOverride,
        _logosDirectoryOverride = logosDirectoryOverride;

  final Database _database;
  final BackupMetadataStore _metadata;
  final CloudBackupPort _cloud;
  final Logger _logger;
  final BackupEncryptionService _encryption;
  final BackupPackager _packager;
  final Connectivity _connectivity;
  final Directory? _backupsDirectoryOverride;
  final Directory? _logosDirectoryOverride;
  final Uuid _uuid = const Uuid();

  Future<BackupStatus> getStatus() async {
    final now = DateTime.now();
    final lastAt = await _metadata.lastBackupAt();
    final entries = await listBackups();
    final storageUsed = entries.fold<int>(0, (sum, entry) => sum + entry.fileSizeBytes);
    final connectedLabel = await _cloud.connectedAccountLabel();

    return BackupStatus(
      lastBackupAt: lastAt,
      lastBackupLabel: _metadata.formatLastBackupLabel(lastAt, now),
      isConnected: await _cloud.isConnected(),
      connectedAccountLabel:
          connectedLabel ?? 'Connect nahi hai',
      storageUsedBytes: storageUsed,
      backupCount: entries.length,
      autoFrequency: await _metadata.autoFrequency(),
      wifiOnly: await _metadata.wifiOnly(),
      isStale: _metadata.isStale(lastAt, now),
      isRunning: await _metadata.isRunning(),
      lastError: await _metadata.lastError(),
    );
  }

  Future<BackupEntry> createBackup({required BackupType type}) async {
    await _metadata.setRunning(true);
    try {
      final business = await _readBusiness();
      if (business == null) {
        throw StateError('Business profile missing — backup cannot run');
      }

      final createdAt = DateTime.now();
      final backupId = _uuid.v4();
      final salt = _encryption.generateSalt();
      final manifest = BackupManifest(
        backupId: backupId,
        businessId: business.id,
        businessName: business.name,
        createdAt: createdAt,
        schemaVersion: AppConstants.databaseVersion,
        appVersion: '1.0.0+5',
        type: type,
        encryptedSize: 0,
        salt: salt,
      );

      final databasePath = await _resolveDatabasePath();
      final logosDir = await _logosDirectory();
      final preferences = await _metadata.exportAllPreferences();

      final encryptedFile = await _packager.createEncryptedBackup(
        manifest: manifest,
        databasePath: databasePath,
        logosDirectory: logosDir,
        preferences: preferences,
      );

      final saved = await _saveBackupFile(
        backupId: backupId,
        createdAt: createdAt,
        bytes: encryptedFile,
        manifest: manifest.copyWithEncryptedSize(encryptedFile.length),
      );

      await _pruneOldBackups();
      await _metadata.recordBackup(createdAt);

      if (type == BackupType.automatic && await _cloud.isConnected()) {
        await _cloud.uploadBackup(File(saved.filePath));
      }

      _logger.info('Backup created: ${saved.id} (${type.name})');
      return saved;
    } catch (error, stackTrace) {
      await _metadata.setLastError('$error');
      _logger.error('Backup failed', error, stackTrace);
      rethrow;
    } finally {
      await _metadata.setRunning(false);
    }
  }

  Future<BackupEntry> restoreBackup(BackupEntry entry) async {
    BackupEntry? rollback;
    try {
      rollback = await createBackup(type: BackupType.preRestore);
      await _applyBackupFile(await File(entry.filePath).readAsBytes());
      _logger.info('Backup restored from ${entry.id}');
      return entry;
    } catch (error, stackTrace) {
      _logger.error('Restore failed — attempting rollback', error, stackTrace);
      if (rollback != null) {
        try {
          await _applyBackupFile(await File(rollback.filePath).readAsBytes());
          _logger.info('Rollback restore succeeded');
        } catch (rollbackError, rollbackStack) {
          _logger.error(
            'Rollback restore failed',
            rollbackError,
            rollbackStack,
          );
        }
      }
      await _metadata.setLastError('Restore fail: $error');
      rethrow;
    }
  }

  Future<BackupEntry> importBackupFile(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final bundle = await _packager.readEncryptedBackup(fileBytes: bytes);

    final imported = await _saveBackupFile(
      backupId: bundle.manifest.backupId,
      createdAt: bundle.manifest.createdAt,
      bytes: bytes,
      manifest: bundle.manifest.copyWithType(BackupType.imported),
    );

    await _pruneOldBackups();
    return imported;
  }

  Future<void> restoreImportedFile(String sourcePath) async {
    final entry = await importBackupFile(sourcePath);
    await restoreBackup(entry);
  }

  Future<void> exportBackup(BackupEntry entry) async {
    await Share.shareXFiles(
      [XFile(entry.filePath, name: p.basename(entry.filePath))],
      subject: 'BT Business Backup',
    );
  }

  Future<void> deleteBackup(BackupEntry entry) async {
    final file = File(entry.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<BackupEntry>> listBackups() async {
    final directory = await _backupsDirectory();
    if (!await directory.exists()) return [];

    final files = <BackupEntry>[];
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      if (!entity.path.endsWith(BackupFormat.fileExtension)) continue;

      try {
        final bytes = await entity.readAsBytes();
        final bundle = await _packager.readEncryptedBackup(fileBytes: bytes);
        files.add(
          BackupEntry(
            id: bundle.manifest.backupId,
            filePath: entity.path,
            manifest: bundle.manifest,
            fileSizeBytes: await entity.length(),
          ),
        );
      } catch (error) {
        _logger.warning('Skipping invalid backup file ${entity.path}: $error');
      }
    }

    files.sort(
      (a, b) => b.manifest.createdAt.compareTo(a.manifest.createdAt),
    );
    return files;
  }

  Future<void> runAutoBackupIfDue({DateTime? reference}) async {
    final now = reference ?? DateTime.now();
    final frequency = await _metadata.autoFrequency();
    if (frequency == AutoBackupFrequency.off) return;

    if (!await _networkAllowed()) return;
    if (!await _isAutoBackupDue(now, frequency)) return;

    await createBackup(type: BackupType.automatic);
  }

  Future<bool> _isAutoBackupDue(
    DateTime now,
    AutoBackupFrequency frequency,
  ) async {
    final lastAt = await _metadata.lastBackupAt();
    if (lastAt == null) {
      return now.hour >= BackupFormat.autoBackupHour;
    }

    switch (frequency) {
      case AutoBackupFrequency.daily:
        final lastDay = DateTime(lastAt.year, lastAt.month, lastAt.day);
        final today = DateTime(now.year, now.month, now.day);
        return today.isAfter(lastDay) && now.hour >= BackupFormat.autoBackupHour;
      case AutoBackupFrequency.weekly:
        return now.difference(lastAt).inDays >= 7 &&
            now.hour >= BackupFormat.autoBackupHour;
      case AutoBackupFrequency.monthly:
        return (now.month != lastAt.month || now.year != lastAt.year) &&
            now.hour >= BackupFormat.autoBackupHour;
      case AutoBackupFrequency.off:
        return false;
    }
  }

  Future<bool> _networkAllowed() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;

    final wifiOnly = await _metadata.wifiOnly();
    if (!wifiOnly) return true;

    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  Future<void> _applyBackupFile(Uint8List fileBytes) async {
    final bundle = await _packager.readEncryptedBackup(fileBytes: fileBytes);
    if (!backupSchemaSupported(bundle.manifest.schemaVersion)) {
      throw FormatException(
        'Backup schema ${bundle.manifest.schemaVersion} is newer than app',
      );
    }

    final databasePath = await _resolveDatabasePath();
    await AppDatabase.close();

    final dbFile = File(databasePath);
    await dbFile.parent.create(recursive: true);
    await dbFile.writeAsBytes(bundle.databaseBytes, flush: true);

    final logosDir = await _logosDirectory();
    if (await logosDir.exists()) {
      await logosDir.delete(recursive: true);
    }
    await logosDir.create(recursive: true);
    for (final entry in bundle.logoFiles.entries) {
      await File(p.join(logosDir.path, entry.key))
          .writeAsBytes(entry.value, flush: true);
    }

    await _metadata.importPreferences(bundle.preferences);
    if (_backupsDirectoryOverride == null) {
      await AppDatabase.open();
    }
  }

  Future<BackupEntry> _saveBackupFile({
    required String backupId,
    required DateTime createdAt,
    required Uint8List bytes,
    required BackupManifest manifest,
  }) async {
    final directory = await _backupsDirectory();
    await directory.create(recursive: true);

    final stamp = createdAt.toIso8601String().replaceAll(':', '-');
    final fileName = 'backup_$stamp$backupId${BackupFormat.fileExtension}';
    final filePath = p.join(directory.path, fileName);
    await File(filePath).writeAsBytes(bytes, flush: true);

    return BackupEntry(
      id: backupId,
      filePath: filePath,
      manifest: manifest,
      fileSizeBytes: bytes.length,
    );
  }

  Future<void> _pruneOldBackups() async {
    final entries = await listBackups();
    if (entries.length <= BackupFormat.maxHistoryCount) return;

    final removable = entries.sublist(BackupFormat.maxHistoryCount);
    for (final entry in removable) {
      if (entry.manifest.type == BackupType.preRestore) continue;
      await deleteBackup(entry);
    }
  }

  Future<Directory> _backupsDirectory() async {
    if (_backupsDirectoryOverride != null) return _backupsDirectoryOverride!;
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'backups'));
  }

  Future<Directory> _logosDirectory() async {
    if (_logosDirectoryOverride != null) return _logosDirectoryOverride!;
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'logos'));
  }

  Future<String> _resolveDatabasePath() async {
    final path = _database.path;
    if (path != null &&
        path.isNotEmpty &&
        path != inMemoryDatabasePath &&
        !path.startsWith(':memory:')) {
      return path;
    }
    return DatabasePaths.resolve();
  }

  Future<_BusinessSnapshot?> _readBusiness() async {
    final rows = await _database.query(BusinessTable.tableName, limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return _BusinessSnapshot(
      id: row[BusinessTable.id]! as String,
      name: row[BusinessTable.name]! as String,
    );
  }
}

class _BusinessSnapshot {
  const _BusinessSnapshot({required this.id, required this.name});

  final String id;
  final String name;
}

extension on BackupManifest {
  BackupManifest copyWithEncryptedSize(int size) {
    return BackupManifest(
      backupId: backupId,
      businessId: businessId,
      businessName: businessName,
      createdAt: createdAt,
      schemaVersion: schemaVersion,
      appVersion: appVersion,
      type: type,
      encryptedSize: size,
      salt: salt,
    );
  }

  BackupManifest copyWithType(BackupType value) {
    return BackupManifest(
      backupId: backupId,
      businessId: businessId,
      businessName: businessName,
      createdAt: createdAt,
      schemaVersion: schemaVersion,
      appVersion: appVersion,
      type: value,
      encryptedSize: encryptedSize,
      salt: salt,
    );
  }
}
