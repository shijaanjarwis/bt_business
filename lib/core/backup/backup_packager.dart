import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';
import 'backup_encryption_service.dart';
import 'backup_format.dart';

/// Builds and reads encrypted `.btbackup` archives.
final class BackupPackager {
  BackupPackager(this._encryption);

  final BackupEncryptionService _encryption;

  static const _manifestFileName = 'manifest.json';
  static const _databaseFileName = 'bt_business.db';
  static const _preferencesFileName = 'preferences.json';
  static const _logosDirName = 'logos';

  Future<Uint8List> createEncryptedBackup({
    required BackupManifest manifest,
    required String databasePath,
    required Directory? logosDirectory,
    required Map<String, Object?> preferences,
  }) async {
    final archive = Archive();

    archive.addFile(
      ArchiveFile.bytes(
        _manifestFileName,
        utf8.encode(jsonEncode(manifest.toJson())),
      ),
    );

    final dbFile = File(databasePath);
    if (!await dbFile.exists()) {
      throw const FileSystemException('Database file missing for backup');
    }
    archive.addFile(
      ArchiveFile.bytes(_databaseFileName, await dbFile.readAsBytes()),
    );

    archive.addFile(
      ArchiveFile.bytes(
        _preferencesFileName,
        utf8.encode(jsonEncode(preferences)),
      ),
    );

    if (logosDirectory != null && await logosDirectory.exists()) {
      await for (final entity in logosDirectory.list()) {
        if (entity is File) {
          final relative = p.join(_logosDirName, p.basename(entity.path));
          archive.addFile(
            ArchiveFile.bytes(relative, await entity.readAsBytes()),
          );
        }
      }
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const FormatException('Failed to zip backup payload');
    }
    final zipBytes = Uint8List.fromList(encoded);
    final encrypted = await _encryption.encrypt(
      plainBytes: zipBytes,
      businessId: manifest.businessId,
      saltBase64: manifest.salt,
    );

    return _wrapFile(manifest: manifest, encryptedPayload: encrypted);
  }

  Future<BackupRestoreBundle> readEncryptedBackup({
    required Uint8List fileBytes,
  }) async {
    final parsed = _unwrapFile(fileBytes);
    final manifest = parsed.manifest;
    final decrypted = await _encryption.decrypt(
      encryptedBytes: parsed.encryptedPayload,
      businessId: manifest.businessId,
      saltBase64: manifest.salt,
    );

    final archive = ZipDecoder().decodeBytes(decrypted);
    final embeddedManifest = _readArchiveText(archive, _manifestFileName);
    final embedded = BackupManifest.fromJson(
      jsonDecode(embeddedManifest) as Map<String, Object?>,
    );

    return BackupRestoreBundle(
      manifest: embedded,
      databaseBytes: _readArchiveBytes(archive, _databaseFileName),
      preferences: jsonDecode(
        _readArchiveText(archive, _preferencesFileName),
      ) as Map<String, Object?>,
      logoFiles: _readLogoFiles(archive),
    );
  }

  Uint8List _wrapFile({
    required BackupManifest manifest,
    required Uint8List encryptedPayload,
  }) {
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    final builder = BytesBuilder();
    builder.add(utf8.encode(BackupFormat.magic));
    builder.addByte((BackupFormat.version >> 8) & 0xff);
    builder.addByte(BackupFormat.version & 0xff);
    builder.addByte((manifestBytes.length >> 24) & 0xff);
    builder.addByte((manifestBytes.length >> 16) & 0xff);
    builder.addByte((manifestBytes.length >> 8) & 0xff);
    builder.addByte(manifestBytes.length & 0xff);
    builder.add(manifestBytes);
    builder.add(encryptedPayload);
    return builder.toBytes();
  }

  _ParsedBackupFile _unwrapFile(Uint8List fileBytes) {
    if (fileBytes.length < 10) {
      throw const FormatException('Backup file is too small');
    }

    final magic = utf8.decode(fileBytes.sublist(0, 4));
    if (magic != BackupFormat.magic) {
      throw const FormatException('Not a BT Business backup file');
    }

    final version = (fileBytes[4] << 8) | fileBytes[5];
    if (version != BackupFormat.version) {
      throw FormatException('Unsupported backup version: $version');
    }

    final manifestLength = (fileBytes[6] << 24) |
        (fileBytes[7] << 16) |
        (fileBytes[8] << 8) |
        fileBytes[9];
    final manifestStart = 10;
    final manifestEnd = manifestStart + manifestLength;
    if (manifestEnd > fileBytes.length) {
      throw const FormatException('Corrupt backup manifest');
    }

    final manifestJson = jsonDecode(
      utf8.decode(fileBytes.sublist(manifestStart, manifestEnd)),
    ) as Map<String, Object?>;
    final manifest = BackupManifest.fromJson(manifestJson);

    return _ParsedBackupFile(
      manifest: manifest,
      encryptedPayload: fileBytes.sublist(manifestEnd),
    );
  }

  String _readArchiveText(Archive archive, String name) {
    final file = archive.files.firstWhere(
      (entry) => entry.name == name,
      orElse: () => throw FormatException('Missing $name in backup'),
    );
    return utf8.decode(file.content as List<int>);
  }

  Uint8List _readArchiveBytes(Archive archive, String name) {
    final file = archive.files.firstWhere(
      (entry) => entry.name == name,
      orElse: () => throw FormatException('Missing $name in backup'),
    );
    return Uint8List.fromList(file.content as List<int>);
  }

  Map<String, Uint8List> _readLogoFiles(Archive archive) {
    final logos = <String, Uint8List>{};
    for (final file in archive.files) {
      if (file.name.startsWith('$_logosDirName/')) {
        logos[p.basename(file.name)] =
            Uint8List.fromList(file.content as List<int>);
      }
    }
    return logos;
  }
}

class BackupRestoreBundle {
  const BackupRestoreBundle({
    required this.manifest,
    required this.databaseBytes,
    required this.preferences,
    required this.logoFiles,
  });

  final BackupManifest manifest;
  final Uint8List databaseBytes;
  final Map<String, Object?> preferences;
  final Map<String, Uint8List> logoFiles;
}

class _ParsedBackupFile {
  const _ParsedBackupFile({
    required this.manifest,
    required this.encryptedPayload,
  });

  final BackupManifest manifest;
  final Uint8List encryptedPayload;
}

/// Validates restored database schema version.
bool backupSchemaSupported(int schemaVersion) {
  return schemaVersion <= AppConstants.databaseVersion;
}
