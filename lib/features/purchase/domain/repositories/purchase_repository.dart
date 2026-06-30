import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/result.dart';
import '../entities/purchase_invoice.dart';

/// Persistence contract for purchase invoices.
abstract interface class PurchaseRepository {
  Future<Result<List<PurchaseInvoice>>> getPurchases({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
  });

  Future<Result<List<PurchaseInvoice>>> searchPurchases(String query);

  Future<Result<PurchaseInvoice?>> getPurchase(String id);

  Future<Result<PurchaseInvoice>> savePurchase(SavePurchaseInput input);

  Future<Result<void>> deletePurchase(String id);
}

/// Domain input for creating or updating a purchase invoice.
class SavePurchaseInput {
  const SavePurchaseInput({
    this.id,
    this.invoiceNo,
    required this.date,
    required this.partyId,
    required this.paymentMode,
    required this.gstType,
    required this.lines,
    this.notes,
    this.existingCreatedAt,
  });

  final String? id;
  final String? invoiceNo;
  final DateTime date;
  final String partyId;
  final PaymentMode paymentMode;
  final GstType gstType;
  final List<PurchaseLineInput> lines;
  final String? notes;
  final DateTime? existingCreatedAt;
}
