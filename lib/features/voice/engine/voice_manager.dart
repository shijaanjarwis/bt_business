import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/logger.dart';
import '../data/parsers/business_parser.dart';
import '../data/parsers/rule_voice_parser.dart';
import '../data/providers/local_rule_ai_provider.dart';
import '../data/speech/speech_permission_status.dart';
import '../data/speech/speech_recognition_service.dart';
import '../data/voice_history_store.dart';
import '../domain/ai_provider_interface.dart';
import '../domain/voice_draft.dart';
import '../domain/voice_memory.dart';
import '../engine/voice_memory_engine.dart';

/// Orchestrates speech capture, parsing, memory, and preview preparation.
final class VoiceManager {
  VoiceManager({
    required SpeechRecognitionService speech,
    required AiProviderInterface aiProvider,
    required VoiceHistoryStore history,
    required VoiceMemoryEngine memoryEngine,
    Logger? logger,
  })  : _speech = speech,
        _aiProvider = aiProvider,
        _history = history,
        _memoryEngine = memoryEngine,
        _logger = logger ?? const AppLogger();

  final SpeechRecognitionService _speech;
  final AiProviderInterface _aiProvider;
  final VoiceHistoryStore _history;
  final VoiceMemoryEngine _memoryEngine;
  final Logger _logger;

  LocalRuleAiProvider? get localProvider =>
      _aiProvider is LocalRuleAiProvider ? _aiProvider : null;

  Future<SpeechPermissionStatus> ensureMicrophonePermission() {
    _logger.info('[Voice] requesting microphone permission');
    return _speech.ensureMicrophonePermission();
  }

  Future<bool> initializeSpeech(String localeId) {
    _logger.info('[Voice] initialize speech locale=$localeId');
    return _speech.initialize(localeId: localeId);
  }

  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function(String error) onError,
    required void Function() onDone,
    void Function(double level)? onSoundLevel,
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 6),
  }) {
    _logger.info('[Voice] start listening');
    return _speech.startListening(
      onResult: (words) {
        _logger.info('[Voice] transcript update: "$words"');
        onResult(words);
      },
      onError: (message) {
        _logger.warning('[Voice] recognition error: $message');
        onError(message);
      },
      onDone: () {
        _logger.info('[Voice] listening stopped');
        onDone();
      },
      onSoundLevel: onSoundLevel,
      listenFor: listenFor,
      pauseFor: pauseFor,
    );
  }

  Future<void> stopListening() {
    _logger.info('[Voice] stop listening');
    return _speech.stopListening();
  }

  Future<void> cancelListening() {
    _logger.info('[Voice] cancel listening');
    return _speech.cancelListening();
  }

  Future<void> recordHistory(String transcript) {
    _logger.info('[Voice] history saved: "$transcript"');
    return _history.add(transcript);
  }

  Future<VoiceEnrichedResult> parseTranscript(String text) {
    _logger.info('[Voice] parse transcript: "$text"');
    return _aiProvider.parseTranscript(text);
  }

  Future<VoiceEnrichedResult> applyClarification({
    required VoiceDraft draft,
    required VoiceClarification clarification,
    required String answer,
    required String rawText,
  }) async {
    final parser = localProvider?.parser ?? BusinessParser();
    final updated = applyClarificationAnswer(draft, clarification, answer);
    final revalidated = revalidateVoiceDraft(updated, parser);
    return _memoryEngine.enrich(parseResult: revalidated, rawText: rawText);
  }

  Future<void> learnFromSave(VoiceDraft draft) {
    return _memoryEngine.learnFromSave(draft);
  }
}
