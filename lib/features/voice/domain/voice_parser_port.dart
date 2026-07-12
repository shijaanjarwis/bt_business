import 'voice_draft.dart';

/// Modular voice NLU port — rule engine today, LLM/local AI later.
abstract interface class VoiceParserPort {
  VoiceParseResult parse(String text, {DateTime? referenceDate});
}
