import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_providers.dart';
import '../backup/backup_service.dart';
import '../di/core_providers.dart';
import '../logging/logger.dart';

/// Runs silent auto-backup checks after 2 AM when network allows.
final class AutoBackupRunner {
  AutoBackupRunner(this._backupFactory, this._logger);

  final BackupService Function() _backupFactory;
  final Logger _logger;

  Future<void> checkAndRun() async {
    try {
      await _backupFactory().runAutoBackupIfDue();
    } catch (error) {
      _logger.warning('Auto backup check failed: $error');
    }
  }
}

final autoBackupRunnerProvider = Provider<AutoBackupRunner>((ref) {
  return AutoBackupRunner(
    () => ref.read(backupServiceProvider),
    ref.watch(loggerProvider),
  );
});
