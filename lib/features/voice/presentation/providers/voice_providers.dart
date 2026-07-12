import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/localization/language_provider.dart';
import '../../data/memory/voice_business_memory_store.dart';
import '../../data/parsers/business_parser.dart';
import '../../data/providers/local_rule_ai_provider.dart';
import '../../data/speech/speech_recognition_service.dart';
import '../../data/voice_history_store.dart';
import '../../domain/ai_provider_interface.dart';
import '../../domain/voice_parser_interface.dart';
import '../../engine/voice_manager.dart';
import '../../engine/voice_memory_engine.dart';

final voiceBusinessMemoryStoreProvider = Provider<VoiceBusinessMemoryStore>((ref) {
  return VoiceBusinessMemoryStore.create();
});

final voiceMemoryEngineProvider = Provider<VoiceMemoryEngine>((ref) {
  return VoiceMemoryEngine(
    store: ref.watch(voiceBusinessMemoryStoreProvider),
    parser: ref.watch(voiceParserProvider) as BusinessParser,
  );
});

final voiceParserProvider = Provider<VoiceParserInterface>((ref) {
  return BusinessParser();
});

final aiProviderProvider = Provider<AiProviderInterface>((ref) {
  return LocalRuleAiProvider(
    memoryEngine: ref.watch(voiceMemoryEngineProvider),
    parser: ref.watch(voiceParserProvider) as BusinessParser,
  );
});

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>((ref) {
  return SpeechRecognitionService();
});

/// Backward-compatible alias.
final speechRecognizerProvider = speechRecognitionServiceProvider;

final voiceManagerProvider = Provider<VoiceManager>((ref) {
  return VoiceManager(
    speech: ref.watch(speechRecognitionServiceProvider),
    aiProvider: ref.watch(aiProviderProvider),
    history: ref.watch(voiceHistoryStoreProvider),
    memoryEngine: ref.watch(voiceMemoryEngineProvider),
    logger: ref.watch(loggerProvider),
  );
});

final voiceHistoryStoreProvider = Provider<VoiceHistoryStore>((ref) {
  return VoiceHistoryStore.create();
});

final voiceHistoryProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(voiceHistoryStoreProvider).readAll();
});

final voiceLocaleProvider = Provider<String>((ref) {
  return ref.watch(assistantLanguageProvider).voiceLocaleCode;
});
