import 'package:bt_business/features/voice/data/parsers/rule_voice_parser.dart';
import 'package:bt_business/features/voice/domain/voice_intent_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RuleVoiceParser parser;

  setUp(() {
    parser = RuleVoiceParser();
  });

  group('RuleVoiceParser', () {
    test('parses full sale with split payment and reminder', () {
      final result = parser.parse(
        'Kaleem bhai ko 25 kilo sariya 68 rupaye kilo bechi. '
        '1000 rupaye cash mil gaye. 500 upi aa gaya. baaki udhaar. '
        '15 july ko reminder laga do.',
        referenceDate: DateTime(2026, 7, 13),
      );

      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.sale);
      expect(result.draft.partyName, 'Kaleem Bhai');
      expect(result.draft.itemName, 'Sariya');
      expect(result.draft.quantity, 25);
      expect(result.draft.rate, 68);
      expect(result.draft.paymentBreakdown.cash, 1000);
      expect(result.draft.paymentBreakdown.upi, 500);
      expect(result.draft.creditAmount, 200);
      expect(result.draft.reminderDate, DateTime(2026, 7, 15));
    });

    test('parses Mateen sunglasses cash sale', () {
      final result = parser.parse('Mateen ko 20 piece sunglasses 650 rupaye cash beche.');
      expect(result.draft.intent, VoiceIntentType.sale);
      expect(result.draft.partyName, 'Mateen');
      expect(result.draft.quantity, 20);
      expect(result.draft.unit, 'Pcs');
      expect(result.draft.itemName, 'Sunglasses');
      expect(result.draft.rate, 650);
    });

    test('parses Raaj cash received', () {
      final result = parser.parse('Raaj se 15000 cash mila.');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.paymentReceived);
      expect(result.draft.partyName, 'Raaj');
      expect(result.draft.amount, 15000);
      expect(result.draft.paymentBreakdown.cash, 15000);
    });

    test('parses diesel expense with likho', () {
      final result = parser.parse('Aaj diesel ka 500 kharcha likho.');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.expense);
      expect(result.draft.expenseName, 'Diesel');
      expect(result.draft.amount, 500);
    });

    test('parses Ramesh bank received', () {
      final result = parser.parse('Ramesh se 25000 bank se mila.');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.paymentReceived);
      expect(result.draft.partyName, 'Ramesh');
      expect(result.draft.amount, 25000);
      expect(result.draft.paymentBreakdown.bank, 25000);
    });

    test('parses Rafiq udhaar sale', () {
      final result = parser.parse('Rafiq ko 30 kg sariya 72 rupaye kilo udhaar di.');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.sale);
      expect(result.draft.partyName, 'Rafiq');
      expect(result.draft.itemName, 'Sariya');
      expect(result.draft.quantity, 30);
      expect(result.draft.rate, 72);
      expect(result.draft.creditAmount, 2160);
    });

    test('parses kal shaam reminder for Mateen', () {
      final result = parser.parse(
        'Kal shaam 6 baje Mateen ko payment yaad dilana.',
        referenceDate: DateTime(2026, 7, 13),
      );
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.reminder);
      expect(result.draft.partyName, 'Mateen');
      expect(result.draft.reminderDate, DateTime(2026, 7, 14));
      expect(result.draft.reminderTime, contains('Shaam'));
    });

    test('parses aaj box paint purchase', () {
      final result = parser.parse('Aaj 15 box paint kharide.');
      expect(result.draft.intent, VoiceIntentType.purchase);
      expect(result.draft.quantity, 15);
      expect(result.draft.unit, 'Box');
      expect(result.draft.itemName, 'Paint');
      expect(result.needsClarification, isTrue);
      expect(result.clarification?.field.name, 'party');
    });

    test('parses receive payment command', () {
      final result = parser.parse('Kaleem se 15000 rupaye mile');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.paymentReceived);
      expect(result.draft.partyName, 'Kaleem');
      expect(result.draft.amount, 15000);
    });

    test('parses payment given command', () {
      final result = parser.parse('Sharma Traders ko 12000 diye');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.paymentPaid);
      expect(result.draft.partyName, 'Sharma Traders');
      expect(result.draft.amount, 12000);
    });

    test('parses expense command', () {
      final result = parser.parse('500 diesel ka kharcha');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.expense);
      expect(result.draft.expenseName, 'Diesel');
      expect(result.draft.amount, 500);
    });

    test('parses create party command', () {
      final result = parser.parse('Mateen naam ki party banao');
      expect(result.needsClarification, isFalse);
      expect(result.draft.intent, VoiceIntentType.createParty);
      expect(result.draft.partyName, 'Mateen');
    });

    test('asks when item missing on sale', () {
      final result = parser.parse('Mateen ko maal becha');
      expect(result.needsClarification, isTrue);
      expect(result.clarification?.question, 'Kaunsa maal?');
    });

    test('parses mixed hindi english sale', () {
      final result = parser.parse('Kaleem ko 20 kg angle sale kiya 50 rupaye kilo');
      expect(result.draft.intent, VoiceIntentType.sale);
      expect(result.draft.partyName, 'Kaleem');
      expect(result.draft.itemName, 'Angle');
      expect(result.draft.quantity, 20);
    });
  });
}
