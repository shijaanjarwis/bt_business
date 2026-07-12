/// Voice Module — speech input and voice-driven commands.
library;

export 'domain/ai_provider_interface.dart';
export 'domain/voice_draft.dart';
export 'domain/voice_intent_type.dart';
export 'domain/voice_memory.dart';
export 'domain/voice_memory_engine.dart';
export 'domain/voice_parser_interface.dart';
export 'domain/voice_parser_port.dart';
export 'domain/voice_session.dart';
export 'engine/preview_generator.dart';
export 'engine/voice_manager.dart';
export 'engine/voice_memory_engine.dart';
export 'data/parsers/business_parser.dart';
export 'data/parsers/natural_business_parser.dart';
export 'data/parsers/parser_confidence_scorer.dart';
export 'data/providers/local_rule_ai_provider.dart';
export 'data/speech/speech_recognition_service.dart';
export 'presentation/pages/voice_assistant_page.dart';
export 'presentation/providers/voice_providers.dart';
