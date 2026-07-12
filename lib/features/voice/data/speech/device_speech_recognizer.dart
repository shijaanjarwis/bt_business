import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/logger.dart';
import 'microphone_permission_service.dart';
import 'speech_permission_status.dart';
import 'speech_recognizer_port.dart';

/// On-device speech recognition via [speech_to_text].
final class DeviceSpeechRecognizer implements SpeechRecognizerPort {
  DeviceSpeechRecognizer({
    SpeechToText? speech,
    MicrophonePermissionService? permissionService,
    Logger? logger,
  })  : _speech = speech ?? SpeechToText(),
        _permission = permissionService ?? const MicrophonePermissionService(),
        _logger = logger ?? const AppLogger();

  final SpeechToText _speech;
  final MicrophonePermissionService _permission;
  final Logger _logger;

  bool _initialized = false;
  String _localeId = 'hi-IN';
  bool _receivedWords = false;
  int _attempt = 0;

  @override
  bool get isAvailable => _initialized;

  @override
  Future<SpeechPermissionStatus> ensureMicrophonePermission() {
    return _permission.ensureGranted();
  }

  @override
  Future<bool> initialize({required String localeId}) async {
    _localeId = localeId;
    _logger.info('[Voice STT] initialize locale=$localeId');

    final permission = await ensureMicrophonePermission();
    if (permission != SpeechPermissionStatus.granted) {
      _logger.warning('[Voice STT] microphone permission=$permission');
      _initialized = false;
      return false;
    }

    _initialized = await _speech.initialize(
      onError: (error) => _logger.warning('[Voice STT] init error: ${error.errorMsg}'),
      onStatus: (status) => _logger.info('[Voice STT] status: $status'),
      debugLogging: false,
    );

    _logger.info('[Voice STT] initialize result=$_initialized');
    return _initialized;
  }

  @override
  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function(String error) onError,
    required void Function() onDone,
    void Function(double level)? onSoundLevel,
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 6),
  }) async {
    _attempt += 1;
    final attemptId = _attempt;
    _receivedWords = false;

    _logger.info('[Voice STT] listen start attempt=$attemptId locale=$_localeId');

    if (!_initialized) {
      final ready = await initialize(localeId: _localeId);
      if (!ready) {
        onError('Mic permission ya voice service available nahi hai');
        _logger.warning('[Voice STT] listen aborted attempt=$attemptId — not initialized');
        return;
      }
    }

    final locales = await _speech.locales();
    var locale = _localeId;
    if (!locales.any((entry) => entry.localeId == locale)) {
      final prefix = locale.split('-').first;
      locale = locales
              .where((entry) => entry.localeId.startsWith(prefix))
              .map((entry) => entry.localeId)
              .firstOrNull ??
          locales.first.localeId;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          _logger.info(
            '[Voice STT] attempt=$attemptId partial=${!result.finalResult} words="$words"',
          );
          if (words.isNotEmpty) {
            _receivedWords = true;
            onResult(words);
          }
          if (result.finalResult) {
            _logger.info('[Voice STT] attempt=$attemptId final words="$words"');
            onDone();
          }
        },
        onSoundLevelChange: (level) {
          onSoundLevel?.call(_normalizeSoundLevel(level));
        },
        listenOptions: SpeechListenOptions(
          localeId: locale,
          listenMode: ListenMode.dictation,
          partialResults: true,
          listenFor: listenFor,
          pauseFor: pauseFor,
          cancelOnError: true,
          onDevice: false,
        ),
      );
      _logger.info('[Voice STT] listen session active attempt=$attemptId locale=$locale');
    } catch (error, stack) {
      _logger.error('[Voice STT] listen failed attempt=$attemptId', error, stack);
      onError('Sunai shuru nahi ho payi. Phir se koshish karein.');
    }
  }

  @override
  Future<void> stopListening() async {
    _logger.info('[Voice STT] stop listening attempt=$_attempt received=$_receivedWords');
    await _speech.stop();
  }

  @override
  Future<void> cancelListening() async {
    _logger.info('[Voice STT] cancel listening attempt=$_attempt');
    await _speech.cancel();
  }

  bool get receivedWords => _receivedWords;

  SpeechRecognitionError? get lastError => _speech.lastError;

  static double _normalizeSoundLevel(double raw) {
    // iOS reports dB (~-50..0); Android may differ — clamp to 0..1.
    if (raw <= 0) {
      return ((raw + 50) / 50).clamp(0.0, 1.0);
    }
    return raw.clamp(0.0, 1.0);
  }
}
