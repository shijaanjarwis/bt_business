import 'package:bt_business/core/constants/item_unit_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unit library includes required categories', () {
    expect(ItemUnitLibrary.all.any((e) => e.name == 'Kg'), isTrue);
    expect(ItemUnitLibrary.all.any((e) => e.name == 'Quintal'), isTrue);
    expect(ItemUnitLibrary.all.any((e) => e.name == 'Litre'), isTrue);
    expect(ItemUnitLibrary.all.any((e) => e.name == 'Bigha'), isTrue);
    expect(ItemUnitLibrary.all.any((e) => e.name == 'Cubic Meter'), isTrue);
    expect(ItemUnitLibrary.all.any((e) => e.name == 'Tola'), isTrue);
  });

  test('unit search finds by name and category', () {
    expect(ItemUnitLibrary.search('kg'), isNotEmpty);
    expect(ItemUnitLibrary.search('weight').every((e) => e.category == 'Weight'),
        isTrue);
    expect(ItemUnitLibrary.search('nos').first.name, 'Nos');
  });

  test('count units require whole-number quantities', () {
    expect(ItemUnitLibrary.allowsDecimalQuantity('Piece'), isFalse);
    expect(ItemUnitLibrary.allowsDecimalQuantity('Packet'), isFalse);
    expect(ItemUnitLibrary.allowsDecimalQuantity('Box'), isFalse);
    expect(ItemUnitLibrary.allowsDecimalQuantity('Rod'), isFalse);
  });

  test('weight and measure units allow decimal quantities', () {
    expect(ItemUnitLibrary.allowsDecimalQuantity('Kg'), isTrue);
    expect(ItemUnitLibrary.allowsDecimalQuantity('Gram'), isTrue);
    expect(ItemUnitLibrary.allowsDecimalQuantity('Litre'), isTrue);
    expect(ItemUnitLibrary.allowsDecimalQuantity('Meter'), isTrue);
    expect(ItemUnitLibrary.allowsDecimalQuantity('Foot'), isTrue);
  });

  test('quantity clamp never goes below 1', () {
    expect(ItemUnitLibrary.clampQuantity(0, 'Piece'), 1);
    expect(ItemUnitLibrary.clampQuantity(0.5, 'Piece'), 1);
    expect(ItemUnitLibrary.clampQuantity(125.7, 'Piece'), 126);
    expect(ItemUnitLibrary.clampQuantity(2.5, 'Kg'), 2.5);
  });
}
