import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognizer_port.dart';

/// On-device speech recognition via [speech_to_text].
final class DeviceSpeechRecognizer implements SpeechRecognizerPort {
  DeviceSpeechRecognizer({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  String _localeId = 'hi-IN';

  @override
  bool get isAvailable => _initialized;

  @override
  Future<bool> initialize({required String localeId}) async {
    _localeId = localeId;
    _initialized = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  @override
  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function(String error) onError,
    required void Function() onDone,
  }) async {
    if (!_initialized) {
      onError('Mic tayyar nahi hai');
      return;
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

    await _speech.listen(
      localeId: locale,
      listenMode: ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onDone();
        }
      },
    );
  }

  @override
  Future<void> stopListening() => _speech.stop();

  @override
  Future<void> cancelListening() => _speech.cancel();
}
