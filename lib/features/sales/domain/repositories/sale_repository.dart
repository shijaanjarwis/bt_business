import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/result.dart';
import '../entities/sale_invoice.dart';

/// Persistence contract for sales invoices.
abstract interface class SaleRepository {
  Future<Result<List<SaleInvoice>>> getSales({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
  });

  Future<Result<List<SaleInvoice>>> searchSales(String query);

  Future<Result<SaleInvoice?>> getSale(String id);

  Future<Result<SaleInvoice>> saveSale(SaveSaleInput input);

  Future<Result<void>> deleteSale(String id);
}

/// Domain input for creating or updating a sale invoice.
class SaveSaleInput {
  const SaveSaleInput({
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
  final List<SaleLineInput> lines;
  final String? notes;
  final DateTime? existingCreatedAt;
}
