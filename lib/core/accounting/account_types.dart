/// Ledger account type identifiers stored in SQLite.
abstract final class AccountTypes {
  static const String cash = 'cash';
  static const String bank = 'bank';
  static const String sales = 'sales';
  static const String purchase = 'purchase';
  static const String receivable = 'receivable';
  static const String payable = 'payable';
  static const String stock = 'stock';
  static const String expense = 'expense';
  static const String equity = 'equity';
  static const String cgstPayable = 'cgst_payable';
  static const String sgstPayable = 'sgst_payable';
  static const String igstPayable = 'igst_payable';
  static const String cogs = 'cogs';
}
