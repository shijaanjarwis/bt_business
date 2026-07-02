import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../domain/entities/sale_entry.dart';

/// Maps between [SaleEntry] entities and SQLite rows.
final class SaleEntryModel {
  const SaleEntryModel({
    required this.entry,
    required this.partyName,
  });

  final SaleEntry entry;
  final String partyName;

  factory SaleEntryModel.fromJoinedMap(
    Map<String, Object?> map, {
    required List<SaleLine> lines,
  }) {
    return SaleEntryModel(
      partyName: map['party_name']! as String,
      entry: SaleEntry(
        id: map[TransactionsTable.id]! as String,
        businessId: map[TransactionsTable.businessId]! as String,
        entryNo: map[TransactionsTable.invoiceNo] as String? ?? '',
        date: DateTime.parse(map[TransactionsTable.date]! as String),
        partyId: map[TransactionsTable.partyId]! as String,
        partyName: map['party_name']! as String,
        notes: map[TransactionsTable.notes] as String?,
        paymentMode: PaymentMode.fromCode(
          map[TransactionsTable.paymentMode]! as String? ?? PaymentMode.cash.code,
        ),
        gstType: GstType.fromCode(
          map[TransactionsTable.gstType]! as String? ?? GstType.intra.code,
        ),
        subtotal: (map[TransactionsTable.subtotal] as num?)?.toDouble() ?? 0,
        discountTotal: (map[TransactionsTable.discountTotal] as num?)?.toDouble() ?? 0,
        taxableTotal: (map[TransactionsTable.taxableTotal] as num?)?.toDouble() ?? 0,
        cgstTotal: (map[TransactionsTable.cgstTotal] as num?)?.toDouble() ?? 0,
        sgstTotal: (map[TransactionsTable.sgstTotal] as num?)?.toDouble() ?? 0,
        igstTotal: (map[TransactionsTable.igstTotal] as num?)?.toDouble() ?? 0,
        grandTotal: (map[TransactionsTable.totalAmount] as num?)?.toDouble() ?? 0,
        paidAmount: (map[TransactionsTable.paidAmount] as num?)?.toDouble() ?? 0,
        dueAmount: (map[TransactionsTable.dueAmount] as num?)?.toDouble() ?? 0,
        reminderDate: ReminderService.parseReminderDate(
          map[TransactionsTable.reminderDate] as String?,
        ),
        lines: lines,
        createdAt: DateTime.parse(map[TransactionsTable.createdAt]! as String),
        updatedAt: DateTime.parse(map[TransactionsTable.updatedAt]! as String),
      ),
    );
  }

  static SaleLine lineFromMap(Map<String, Object?> map) {
    return SaleLine(
      id: map[TransactionLinesTable.id]! as String,
      transactionId: map[TransactionLinesTable.transactionId]! as String,
      itemId: map[TransactionLinesTable.itemId]! as String,
      itemName: map[TransactionLinesTable.itemName]! as String,
      hsnSac: map[TransactionLinesTable.hsnSac] as String?,
      qty: (map[TransactionLinesTable.qty] as num).toDouble(),
      rate: (map[TransactionLinesTable.rate] as num).toDouble(),
      discountAmount: (map[TransactionLinesTable.discountAmount] as num?)?.toDouble() ?? 0,
      gstRate: (map[TransactionLinesTable.gstRate] as num?)?.toDouble() ?? 0,
      taxableAmount: (map[TransactionLinesTable.taxableAmount] as num?)?.toDouble() ?? 0,
      cgstAmount: (map[TransactionLinesTable.cgstAmount] as num?)?.toDouble() ?? 0,
      sgstAmount: (map[TransactionLinesTable.sgstAmount] as num?)?.toDouble() ?? 0,
      igstAmount: (map[TransactionLinesTable.igstAmount] as num?)?.toDouble() ?? 0,
      lineTotal: (map[TransactionLinesTable.lineTotal] as num?)?.toDouble() ?? 0,
      sortOrder: map[TransactionLinesTable.sortOrder] as int? ?? 0,
    );
  }
}
