import 'voice_draft.dart';

/// Modular voice NLU port — rule engine today, LLM/local AI later.
abstract interface class VoiceParserInterface {
  VoiceParseResult parse(String text, {DateTime? referenceDate});
}

/// Backward-compatible alias.
typedef VoiceParserPort = VoiceParserInterface;
