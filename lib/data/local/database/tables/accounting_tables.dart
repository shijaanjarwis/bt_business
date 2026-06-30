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
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
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
