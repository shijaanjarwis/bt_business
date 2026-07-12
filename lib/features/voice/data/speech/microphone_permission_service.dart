import 'package:permission_handler/permission_handler.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/logger.dart';
import 'speech_permission_status.dart';

/// Requests microphone access and opens system settings when needed.
final class MicrophonePermissionService {
  const MicrophonePermissionService({Logger? logger}) : _logger = logger ?? const AppLogger();

  final Logger _logger;

  Future<SpeechPermissionStatus> ensureGranted() async {
    var status = await Permission.microphone.status;
    _logger.info('[Voice Permission] current status=$status');

    if (status.isGranted) {
      _logger.info('[Voice Permission] result=granted');
      return SpeechPermissionStatus.granted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      _logger.warning('[Voice Permission] result=permanentlyDenied');
      return SpeechPermissionStatus.permanentlyDenied;
    }

    _logger.info('[Voice Permission] requesting microphone');
    status = await Permission.microphone.request();
    _logger.info('[Voice Permission] request result=$status');

    if (status.isGranted) {
      return SpeechPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return SpeechPermissionStatus.permanentlyDenied;
    }
    return SpeechPermissionStatus.denied;
  }

  Future<void> openSettings() => openAppSettings();
}
