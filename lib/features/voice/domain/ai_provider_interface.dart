import 'voice_memory.dart';

/// Pluggable AI / NLU provider — OpenAI, Gemini, offline AI, or local rules.
abstract interface class AiProviderInterface {
  String get providerName;

  /// Parse spoken transcript into a draft with optional memory enrichment.
  Future<VoiceEnrichedResult> parseTranscript(
    String text, {
    DateTime? referenceDate,
  });
}

/// Local rule-based provider identifier — no network, no cost.
abstract final class AiProviderIds {
  static const localRules = 'local_rules';
}
