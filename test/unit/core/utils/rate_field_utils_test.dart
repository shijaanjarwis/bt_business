import 'package:bt_business/core/utils/rate_field_utils.dart';
import 'package:bt_business/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RateFieldUtils', () {
    test('initialText is empty for zero rate', () {
      expect(RateFieldUtils.initialText(0), '');
      expect(RateFieldUtils.initialText(0.0), '');
    });

    test('initialText avoids forced 0.0 prefix for whole numbers', () {
      expect(RateFieldUtils.initialText(1), '1');
      expect(RateFieldUtils.initialText(25), '25');
      expect(RateFieldUtils.initialText(250), '250');
      expect(RateFieldUtils.initialText(1250), '1250');
    });

    test('parse returns zero for empty input', () {
      expect(RateFieldUtils.parse(''), 0);
      expect(RateFieldUtils.parse('   '), 0);
    });

    test('parse reads typed digits directly', () {
      expect(RateFieldUtils.parse('1'), 1);
      expect(RateFieldUtils.parse('25'), 25);
      expect(RateFieldUtils.parse('1250'), 1250);
      expect(RateFieldUtils.parse('12.5'), 12.5);
    });
  });

  group('Validators.entryRate', () {
    test('rejects empty rate with required message', () {
      expect(Validators.entryRate(''), 'Please enter a valid rate.');
      expect(Validators.entryRate('   '), 'Please enter a valid rate.');
    });

    test('rejects zero and negative rates', () {
      expect(Validators.entryRate('0'), 'Please enter a valid rate.');
      expect(Validators.entryRate('-5'), 'Please enter a valid rate.');
    });

    test('accepts positive rates', () {
      expect(Validators.entryRate('250'), isNull);
      expect(Validators.entryRate('1250.5'), isNull);
    });
  });
}
