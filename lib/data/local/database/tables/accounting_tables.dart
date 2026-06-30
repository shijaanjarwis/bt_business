/// SQLite column names for the [accounts] table.
abstract final class AccountsTable {
  static const String tableName = 'accounts';

  static const String id = 'id';
  static const String businessId = 'business_id';
  static const String name = 'name';
  static const String type = 'type';
  static const String isSystem = 'is_system';
  static const String createdAt = 'created_at';
}

/// SQLite column names for the [parties] table.
abstract final class PartiesTable {
  static const String tableName = 'parties';

  static const String id = 'id';
  static const String businessId = 'business_id';
  static const String name = 'name';
  static const String type = 'type';
  static const String phone = 'phone';
  static const String address = 'address';
  static const String gstin = 'gstin';
  static const String creditLimit = 'credit_limit';
  static const String openingBalance = 'opening_balance';
  static const String isActive = 'is_active';
  static const String openingTransactionId = 'opening_transaction_id';
  static const String balance = 'balance';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// SQLite column names for the [transactions] table.
abstract final class TransactionsTable {
  static const String tableName = 'transactions';

  static const String id = 'id';
  static const String businessId = 'business_id';
  static const String type = 'type';
  static const String date = 'date';
  static const String partyId = 'party_id';
  static const String invoiceNo = 'invoice_no';
  static const String notes = 'notes';
  static const String totalAmount = 'total_amount';
  static const String paymentMode = 'payment_mode';
  static const String gstType = 'gst_type';
  static const String subtotal = 'subtotal';
  static const String discountTotal = 'discount_total';
  static const String taxableTotal = 'taxable_total';
  static const String cgstTotal = 'cgst_total';
  static const String sgstTotal = 'sgst_total';
  static const String igstTotal = 'igst_total';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// SQLite column names for the [journal_lines] table.
abstract final class JournalLinesTable {
  static const String tableName = 'journal_lines';

  static const String id = 'id';
  static const String transactionId = 'transaction_id';
  static const String accountId = 'account_id';
  static const String debit = 'debit';
  static const String credit = 'credit';
  static const String partyId = 'party_id';
}

/// SQLite column names for the [items] table.
abstract final class ItemsTable {
  static const String tableName = 'items';

  static const String id = 'id';
  static const String businessId = 'business_id';
  static const String name = 'name';
  static const String unit = 'unit';
  static const String qtyOnHand = 'qty_on_hand';
  static const String purchaseRate = 'purchase_rate';
  static const String saleRate = 'sale_rate';
  static const String gstRate = 'gst_rate';
  static const String hsnSac = 'hsn_sac';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// SQLite column names for the [transaction_lines] table.
abstract final class TransactionLinesTable {
  static const String tableName = 'transaction_lines';

  static const String id = 'id';
  static const String transactionId = 'transaction_id';
  static const String itemId = 'item_id';
  static const String itemName = 'item_name';
  static const String hsnSac = 'hsn_sac';
  static const String qty = 'qty';
  static const String rate = 'rate';
  static const String discountAmount = 'discount_amount';
  static const String gstRate = 'gst_rate';
  static const String taxableAmount = 'taxable_amount';
  static const String cgstAmount = 'cgst_amount';
  static const String sgstAmount = 'sgst_amount';
  static const String igstAmount = 'igst_amount';
  static const String lineTotal = 'line_total';
  static const String sortOrder = 'sort_order';
}

/// SQLite column names for the [stock_movements] table.
abstract final class StockMovementsTable {
  static const String tableName = 'stock_movements';

  static const String id = 'id';
  static const String itemId = 'item_id';
  static const String transactionId = 'transaction_id';
  static const String qtyDelta = 'qty_delta';
  static const String rate = 'rate';
  static const String movementDate = 'movement_date';
}
