import 'dart:io';

import '../../../../data/remote/backup/cloud_backup_port.dart';
import 'google_drive_backup_port.dart';
import 'icloud_backup_port.dart';

/// Selects the zero-cost platform cloud — iCloud on iOS, Google Drive on Android.
abstract final class PlatformCloudBackupFactory {
  static CloudBackupPort create() {
    if (Platform.isIOS) {
      return ICloudBackupPort();
    }
    if (Platform.isAndroid) {
      return GoogleDriveBackupPort();
    }
    return LocalCloudBackupPort();
  }
}
