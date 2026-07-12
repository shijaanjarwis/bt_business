import '../../data/parsers/business_parser.dart';
import '../../domain/ai_provider_interface.dart';
import '../../domain/voice_memory.dart';
import '../../engine/voice_memory_engine.dart';

/// Phase-1 AI provider — local keyword parser + on-device memory only.
final class LocalRuleAiProvider implements AiProviderInterface {
  LocalRuleAiProvider({
    required VoiceMemoryEngine memoryEngine,
    BusinessParser? parser,
  })  : _memoryEngine = memoryEngine,
        _parser = parser ?? BusinessParser();

  final VoiceMemoryEngine _memoryEngine;
  final BusinessParser _parser;

  @override
  String get providerName => AiProviderIds.localRules;

  @override
  Future<VoiceEnrichedResult> parseTranscript(
    String text, {
    DateTime? referenceDate,
  }) async {
    final parsed = _parser.parse(text, referenceDate: referenceDate);
    return _memoryEngine.enrich(parseResult: parsed, rawText: text);
  }

  BusinessParser get parser => _parser;
}
