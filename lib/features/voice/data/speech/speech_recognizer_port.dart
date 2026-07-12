import 'speech_permission_status.dart';

/// Speech-to-text port — device STT today, offline/local later.
abstract interface class SpeechRecognizerPort {
  Future<SpeechPermissionStatus> ensureMicrophonePermission();

  Future<bool> initialize({required String localeId});

  bool get isAvailable;

  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function(String error) onError,
    required void Function() onDone,
    void Function(double level)? onSoundLevel,
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 6),
  });

  Future<void> stopListening();

  Future<void> cancelListening();
}
