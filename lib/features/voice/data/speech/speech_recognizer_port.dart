/// Speech-to-text port — device STT today, offline/local later.
abstract interface class SpeechRecognizerPort {
  Future<bool> initialize({required String localeId});

  bool get isAvailable;

  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function(String error) onError,
    required void Function() onDone,
  });

  Future<void> stopListening();

  Future<void> cancelListening();
}
