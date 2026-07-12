import 'device_speech_recognizer.dart';
import 'speech_permission_status.dart';
import 'speech_recognizer_port.dart';

export 'device_speech_recognizer.dart';
export 'microphone_permission_service.dart';
export 'speech_permission_status.dart';
export 'speech_recognizer_port.dart';

/// Device speech-to-text service — offline-capable architecture for future local STT.
final class SpeechRecognitionService implements SpeechRecognizerPort {
  SpeechRecognitionService({SpeechRecognizerPort? delegate})
      : _delegate = delegate ?? DeviceSpeechRecognizer();

  final SpeechRecognizerPort _delegate;

  @override
  Future<SpeechPermissionStatus> ensureMicrophonePermission() {
    return _delegate.ensureMicrophonePermission();
  }

  @override
  bool get isAvailable => _delegate.isAvailable;

  @override
  Future<bool> initialize({required String localeId}) {
    return _delegate.initialize(localeId: localeId);
  }

  @override
  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function(String error) onError,
    required void Function() onDone,
    void Function(double level)? onSoundLevel,
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 6),
  }) {
    return _delegate.startListening(
      onResult: onResult,
      onError: onError,
      onDone: onDone,
      onSoundLevel: onSoundLevel,
      listenFor: listenFor,
      pauseFor: pauseFor,
    );
  }

  @override
  Future<void> stopListening() => _delegate.stopListening();

  @override
  Future<void> cancelListening() => _delegate.cancelListening();
}
