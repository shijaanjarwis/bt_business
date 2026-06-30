import 'package:bt_business/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.gstin', () {
    test('accepts valid GSTIN', () {
      expect(Validators.gstin('27AAPFU0939F1ZV'), isNull);
    });

    test('rejects invalid GSTIN', () {
      expect(Validators.gstin('INVALID'), isNotNull);
    });

    test('allows empty optional GSTIN', () {
      expect(Validators.gstin(''), isNull);
      expect(Validators.gstin(null), isNull);
    });
  });

  group('Validators.hsnSac', () {
    test('accepts valid HSN code', () {
      expect(Validators.hsnSac('998314'), isNull);
    });

    test('rejects short code', () {
      expect(Validators.hsnSac('123'), isNotNull);
    });
  });

  group('Validators.indianPhone', () {
    test('accepts valid mobile number', () {
      expect(Validators.indianPhone('9876543210'), isNull);
    });

    test('accepts formatted mobile number', () {
      expect(Validators.indianPhone('+91 98765 43210'), isNull);
    });

    test('rejects invalid mobile number', () {
      expect(Validators.indianPhone('12345'), isNotNull);
    });
  });

  group('Validators.positiveAmount', () {
    test('accepts valid amount', () {
      expect(Validators.positiveAmount('1,250.50'), isNull);
    });

    test('rejects zero or negative amount', () {
      expect(Validators.positiveAmount('0'), isNotNull);
      expect(Validators.positiveAmount('-10'), isNotNull);
    });
  });
}
