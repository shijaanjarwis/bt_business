import '../accounting/gst_types.dart';

/// Computed amounts for a single sale line.
class SaleLineAmounts {
  const SaleLineAmounts({
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.lineTotal,
  });

  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double lineTotal;
}

/// GST and discount calculations for sale invoice lines.
abstract final class GstCalculator {
  static SaleLineAmounts computeLine({
    required double qty,
    required double rate,
    required double discountAmount,
    required double gstRate,
    required GstType gstType,
  }) {
    final gross = qty * rate;
    final discount = discountAmount.clamp(0, gross).toDouble();
    final taxable = gross - discount;
    final gstAmount = taxable * gstRate / 100;

    final cgst = gstType == GstType.intra ? gstAmount / 2 : 0.0;
    final sgst = gstType == GstType.intra ? gstAmount / 2 : 0.0;
    final igst = gstType == GstType.inter ? gstAmount : 0.0;

    return SaleLineAmounts(
      grossAmount: gross,
      discountAmount: discount,
      taxableAmount: taxable,
      gstAmount: gstAmount,
      cgstAmount: cgst,
      sgstAmount: sgst,
      igstAmount: igst,
      lineTotal: taxable + gstAmount,
    );
  }

  static ({
    double subtotal,
    double discountTotal,
    double taxableTotal,
    double cgstTotal,
    double sgstTotal,
    double igstTotal,
    double grandTotal,
  }) aggregate(List<SaleLineAmounts> lines) {
    var subtotal = 0.0;
    var discountTotal = 0.0;
    var taxableTotal = 0.0;
    var cgstTotal = 0.0;
    var sgstTotal = 0.0;
    var igstTotal = 0.0;

    for (final line in lines) {
      subtotal += line.grossAmount;
      discountTotal += line.discountAmount;
      taxableTotal += line.taxableAmount;
      cgstTotal += line.cgstAmount;
      sgstTotal += line.sgstAmount;
      igstTotal += line.igstAmount;
    }

    return (
      subtotal: subtotal,
      discountTotal: discountTotal,
      taxableTotal: taxableTotal,
      cgstTotal: cgstTotal,
      sgstTotal: sgstTotal,
      igstTotal: igstTotal,
      grandTotal: taxableTotal + cgstTotal + sgstTotal + igstTotal,
    );
  }
}
