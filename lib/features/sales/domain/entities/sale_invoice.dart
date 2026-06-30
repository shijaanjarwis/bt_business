import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';

/// One product line on a sales invoice.
class SaleLine {
  const SaleLine({
    required this.id,
    required this.transactionId,
    required this.itemId,
    required this.itemName,
    this.hsnSac,
    required this.qty,
    required this.rate,
    required this.discountAmount,
    required this.gstRate,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.lineTotal,
    required this.sortOrder,
  });

  final String id;
  final String transactionId;
  final String itemId;
  final String itemName;
  final String? hsnSac;
  final double qty;
  final double rate;
  final double discountAmount;
  final double gstRate;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double lineTotal;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleLine &&
          id == other.id &&
          transactionId == other.transactionId &&
          itemId == other.itemId &&
          itemName == other.itemName &&
          hsnSac == other.hsnSac &&
          qty == other.qty &&
          rate == other.rate &&
          discountAmount == other.discountAmount &&
          gstRate == other.gstRate &&
          taxableAmount == other.taxableAmount &&
          cgstAmount == other.cgstAmount &&
          sgstAmount == other.sgstAmount &&
          igstAmount == other.igstAmount &&
          lineTotal == other.lineTotal &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        transactionId,
        itemId,
        itemName,
        hsnSac,
        qty,
        rate,
        discountAmount,
        gstRate,
        taxableAmount,
        cgstAmount,
        sgstAmount,
        igstAmount,
        lineTotal,
        sortOrder,
      );
}

/// A completed sales invoice with GST and line items.
class SaleInvoice {
  const SaleInvoice({
    required this.id,
    required this.businessId,
    required this.invoiceNo,
    required this.date,
    required this.partyId,
    required this.partyName,
    this.notes,
    required this.paymentMode,
    required this.gstType,
    required this.subtotal,
    required this.discountTotal,
    required this.taxableTotal,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.igstTotal,
    required this.grandTotal,
    required this.lines,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String invoiceNo;
  final DateTime date;
  final String partyId;
  final String partyName;
  final String? notes;
  final PaymentMode paymentMode;
  final GstType gstType;
  final double subtotal;
  final double discountTotal;
  final double taxableTotal;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double grandTotal;
  final List<SaleLine> lines;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Draft line input before persistence.
class SaleLineInput {
  const SaleLineInput({
    required this.itemId,
    required this.itemName,
    this.hsnSac,
    required this.qty,
    required this.rate,
    this.discountAmount = 0,
    required this.gstRate,
  });

  final String itemId;
  final String itemName;
  final String? hsnSac;
  final double qty;
  final double rate;
  final double discountAmount;
  final double gstRate;
}
