import 'package:bt_business/features/voice/data/parsers/parser_confidence_scorer.dart';
import 'package:bt_business/features/voice/domain/voice_draft.dart';
import 'package:bt_business/features/voice/domain/voice_intent_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('confidence below 90 percent flags careful review', () {
    final score = ParserConfidenceScorer.score(
      const VoiceDraft(
        intent: VoiceIntentType.sale,
        rawText: 'test',
        partyName: 'Mateen',
        itemName: 'Maal',
      ),
    );
    expect(score.needsCarefulReview, isTrue);
    expect(score.overall, lessThan(0.90));
  });

  test('full sale command scores high confidence', () {
    final score = ParserConfidenceScorer.score(
      const VoiceDraft(
        intent: VoiceIntentType.sale,
        rawText: 'test',
        partyName: 'Mateen',
        itemName: 'Sunglasses',
        quantity: 20,
        unit: 'Pcs',
        rate: 650,
      ),
    );
    expect(score.needsCarefulReview, isFalse);
    expect(score.overall, greaterThanOrEqualTo(0.90));
  });
}
