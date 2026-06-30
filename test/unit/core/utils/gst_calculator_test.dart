import 'package:bt_business/core/accounting/gst_types.dart';
import 'package:bt_business/core/utils/gst_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computeLine splits GST for intra-state', () {
    final amounts = GstCalculator.computeLine(
      qty: 2,
      rate: 100,
      discountAmount: 20,
      gstRate: 18,
      gstType: GstType.intra,
    );

    expect(amounts.taxableAmount, 180);
    expect(amounts.gstAmount, closeTo(32.4, 0.001));
    expect(amounts.cgstAmount, closeTo(16.2, 0.001));
    expect(amounts.sgstAmount, closeTo(16.2, 0.001));
    expect(amounts.igstAmount, 0);
    expect(amounts.lineTotal, closeTo(212.4, 0.001));
  });

  test('computeLine uses IGST for inter-state', () {
    final amounts = GstCalculator.computeLine(
      qty: 1,
      rate: 100,
      discountAmount: 0,
      gstRate: 18,
      gstType: GstType.inter,
    );

    expect(amounts.igstAmount, 18);
    expect(amounts.cgstAmount, 0);
    expect(amounts.sgstAmount, 0);
  });

  test('aggregate sums invoice totals', () {
    final line1 = GstCalculator.computeLine(
      qty: 1,
      rate: 100,
      discountAmount: 0,
      gstRate: 18,
      gstType: GstType.intra,
    );
    final line2 = GstCalculator.computeLine(
      qty: 2,
      rate: 50,
      discountAmount: 0,
      gstRate: 5,
      gstType: GstType.intra,
    );

    final totals = GstCalculator.aggregate([line1, line2]);
    expect(totals.grandTotal, closeTo(118 + 105, 0.001));
  });
}
