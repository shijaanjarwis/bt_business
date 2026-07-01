import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';

/// One product line on a purchase invoice.
class PurchaseLine {
  const PurchaseLine({
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
}

/// A completed purchase invoice with GST and line items.
class PurchaseInvoice {
  const PurchaseInvoice({
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
    required this.paidAmount,
    required this.dueAmount,
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
  final double paidAmount;
  final double dueAmount;
  final List<PurchaseLine> lines;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Draft line input before persistence.
class PurchaseLineInput {
  const PurchaseLineInput({
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
