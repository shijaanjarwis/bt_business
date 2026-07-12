import 'package:bt_business/features/voice/data/memory/voice_business_memory_store.dart';
import 'package:bt_business/features/voice/data/parsers/rule_voice_parser.dart';
import 'package:bt_business/features/voice/domain/voice_draft.dart';
import 'package:bt_business/features/voice/domain/voice_intent_type.dart';
import 'package:bt_business/features/voice/domain/voice_memory.dart';
import 'package:bt_business/features/voice/domain/voice_memory_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VoiceBusinessMemoryStore', () {
    test('learns and retrieves party item context', () async {
      final store = VoiceBusinessMemoryStore.create();
      await store.learnFromDraft(
        const VoiceDraft(
          intent: VoiceIntentType.sale,
          rawText: 'test',
          partyName: 'Kaleem',
          itemName: 'Sariya',
          unit: 'Kg',
          rate: 68,
          quantity: 25,
        ),
      );
      await store.warmCache();

      final ctx = store.findPartyItemContext(
        partyName: 'Kaleem',
        intent: VoiceIntentType.sale,
      );

      expect(ctx?.itemName, 'Sariya');
      expect(ctx?.unit, 'Kg');
      expect(ctx?.rate, 68);
    });

    test('keeps only last 50 patterns', () async {
      final store = VoiceBusinessMemoryStore.create();
      for (var i = 0; i < 55; i++) {
        await store.learnFromDraft(
          VoiceDraft(
            intent: VoiceIntentType.sale,
            rawText: 'test $i',
            partyName: 'Party $i',
            itemName: 'Item $i',
            quantity: 1,
            rate: 10,
          ),
        );
      }

      final all = await store.readAll();
      expect(all.length, VoiceBusinessMemoryStore.maxPatterns);
      expect(all.first.partyName, 'Party 54');
    });
  });

  group('VoiceMemoryEngine', () {
    test('fills item from memory on continuation command', () async {
      final store = VoiceBusinessMemoryStore.create();
      final engine = VoiceMemoryEngine(store: store, parser: RuleVoiceParser());

      await store.learnFromDraft(
        const VoiceDraft(
          intent: VoiceIntentType.sale,
          rawText: 'first',
          partyName: 'Kaleem',
          itemName: 'Sariya',
          unit: 'Kg',
          rate: 68,
          quantity: 25,
        ),
      );

      final parse = RuleVoiceParser().parse('Kaleem ko 10 aur bhej do');
      final enriched = await engine.enrich(parseResult: parse, rawText: 'Kaleem ko 10 aur bhej do');

      expect(enriched.draft.itemName, 'Sariya');
      expect(enriched.draft.quantity, 10);
      expect(enriched.confidence[VoiceConfidenceField.item], isNotNull);
      expect(enriched.memoryUsed, isTrue);
    });

    test('fills same rate when user says usi rate par', () async {
      final store = VoiceBusinessMemoryStore.create();
      final engine = VoiceMemoryEngine(store: store, parser: RuleVoiceParser());

      await store.learnFromDraft(
        const VoiceDraft(
          intent: VoiceIntentType.sale,
          rawText: 'first',
          partyName: 'Kaleem',
          itemName: 'Sariya',
          unit: 'Kg',
          rate: 68,
          quantity: 25,
        ),
      );

      final parse = RuleVoiceParser().parse(
        'Kaleem ko 10 kilo sariya usi rate par bechi',
      );
      final enriched = await engine.enrich(
        parseResult: parse,
        rawText: 'Kaleem ko 10 kilo sariya usi rate par bechi',
      );

      expect(enriched.draft.rate, 68);
      expect(enriched.confidence[VoiceConfidenceField.rate], isNotNull);
    });

    test('asks for reminder date when missing', () async {
      final engine = VoiceMemoryEngine(
        store: VoiceBusinessMemoryStore.create(),
        parser: RuleVoiceParser(),
      );

      final parse = RuleVoiceParser().parse(
        'Kaleem ko 25 kilo sariya 68 rupaye kilo bechi reminder laga do',
      );
      final enriched = await engine.enrich(
        parseResult: parse,
        rawText: 'Kaleem ko 25 kilo sariya 68 rupaye kilo bechi reminder laga do',
      );

      expect(enriched.needsClarification, isTrue);
      expect(enriched.clarification?.field, VoiceClarificationField.reminderDate);
    });
  });
}
