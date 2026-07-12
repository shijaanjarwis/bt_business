import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/language_provider.dart';
import '../../data/parsers/rule_voice_parser.dart';
import '../../data/speech/device_speech_recognizer.dart';
import '../../data/speech/speech_recognizer_port.dart';
import '../../data/voice_history_store.dart';
import '../../domain/voice_parser_port.dart';

final voiceParserProvider = Provider<VoiceParserPort>((ref) {
  return RuleVoiceParser();
});

final speechRecognizerProvider = Provider<SpeechRecognizerPort>((ref) {
  return DeviceSpeechRecognizer();
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
