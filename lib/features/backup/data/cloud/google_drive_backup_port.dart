import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../data/remote/backup/cloud_backup_port.dart';
import 'backup_cloud_constants.dart';

/// Android zero-cost backup via the user's Google Drive account.
final class GoogleDriveBackupPort implements CloudBackupPort {
  GoogleDriveBackupPort({GoogleSignIn? signIn})
      : _signIn = signIn ??
            GoogleSignIn(
              scopes: const [drive.DriveApi.driveFileScope],
            );

  final GoogleSignIn _signIn;
  String? _folderId;

  @override
  String get providerName => 'Google Drive';

  @override
  Future<bool> isAvailable() async => Platform.isAndroid;

  @override
  Future<bool> isConnected() async {
    if (!await isAvailable()) return false;
    return _signIn.currentUser != null || (await _signIn.signInSilently()) != null;
  }

  @override
  Future<String?> connectedAccountLabel() async {
    final account = _signIn.currentUser ?? await _signIn.signInSilently();
    return account?.email;
  }

  @override
  Future<void> ensureConnected() async {
    if (!await isAvailable()) {
      throw StateError('Google Drive sirf Android par available hai');
    }

    final account = _signIn.currentUser ??
        await _signIn.signInSilently() ??
        await _signIn.signIn();
    if (account == null) {
      throw StateError('Google account connect nahi hua');
    }
  }

  @override
  Future<String> uploadBackup(
    File backupFile, {
    required String remoteFileName,
  }) async {
    final api = await _driveApi();
    final folderId = await _ensureFolder(api);

    final existing = await _findFile(api, folderId, remoteFileName);
    final media = drive.Media(backupFile.openRead(), await backupFile.length());

    if (existing != null) {
      await api.files.update(
        drive.File()..name = remoteFileName,
        existing,
        uploadMedia: media,
      );
      return existing;
    }

    final created = await api.files.create(
      drive.File()
        ..name = remoteFileName
        ..parents = [folderId],
      uploadMedia: media,
    );
    return created.id ?? remoteFileName;
  }

  @override
  Future<List<CloudBackupRemoteEntry>> listRemoteBackups() async {
    if (!await isConnected()) return [];

    final api = await _driveApi();
    final folderId = await _ensureFolder(api);
    final response = await api.files.list(
      q: "'$folderId' in parents and trashed=false and name contains '.btbackup'",
      orderBy: 'createdTime desc',
      spaces: 'drive',
      $fields: 'files(id,name,createdTime,size)',
    );

    final files = response.files ?? [];
    return files
        .where((file) => file.id != null && file.name != null)
        .map(
          (file) => CloudBackupRemoteEntry(
            remoteId: file.id!,
            fileName: file.name!,
            createdAt: file.createdTime ?? DateTime.now(),
            sizeBytes: int.tryParse('${file.size ?? 0}') ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<File> downloadBackup(String remoteId) async {
    final api = await _driveApi();
    final media = await api.files.get(
      remoteId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final tempDir = await getTemporaryDirectory();
    final localPath = p.join(tempDir.path, 'gdrive_$remoteId.btbackup');
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final file = File(localPath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Future<void> deleteRemoteBackup(String remoteId) async {
    final api = await _driveApi();
    await api.files.delete(remoteId);
  }

  Future<drive.DriveApi> _driveApi() async {
    await ensureConnected();
    final client = await _signIn.authenticatedClient();
    if (client == null) {
      throw StateError('Google Drive access nahi mila');
    }
    return drive.DriveApi(client);
  }

  Future<String> _ensureFolder(drive.DriveApi api) async {
    if (_folderId != null) return _folderId!;

    final query =
        "mimeType='application/vnd.google-apps.folder' and name='${BackupCloudConstants.googleDriveFolderName}' and trashed=false";
    final existing = await api.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id)',
    );

    if (existing.files != null && existing.files!.isNotEmpty) {
      _folderId = existing.files!.first.id;
      return _folderId!;
    }

    final created = await api.files.create(
      drive.File()
        ..name = BackupCloudConstants.googleDriveFolderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    _folderId = created.id;
    if (_folderId == null) {
      throw StateError('Google Drive folder create nahi ho paya');
    }
    return _folderId!;
  }

  Future<String?> _findFile(
    drive.DriveApi api,
    String folderId,
    String fileName,
  ) async {
    final response = await api.files.list(
      q: "'$folderId' in parents and name='$fileName' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    if (response.files == null || response.files!.isEmpty) return null;
    return response.files!.first.id;
  }
}
