import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/errors/result.dart';
import '../entities/sale_entry.dart';

/// Persistence contract for sale register entries.
abstract interface class SaleRepository {
  Future<Result<List<SaleEntry>>> getSales({
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMode? paymentMode,
  });

  Future<Result<List<SaleEntry>>> searchSales(String query);

  Future<Result<SaleEntry?>> getSale(String id);

  Future<Result<SaleEntry>> saveSale(SaveSaleInput input);

  Future<Result<void>> deleteSale(String id);
}

/// Input for creating or updating a sale register entry.
class SaveSaleInput {
  const SaveSaleInput({
    this.id,
    this.entryNo,
    required this.date,
    required this.partyId,
    required this.paymentMode,
    required this.gstType,
    required this.lines,
    this.notes,
    this.existingCreatedAt,
  });

  final String? id;
  final String? entryNo;
  final DateTime date;
  final String partyId;
  final PaymentMode paymentMode;
  final GstType gstType;
  final List<SaleLineInput> lines;
  final String? notes;
  final DateTime? existingCreatedAt;
}
