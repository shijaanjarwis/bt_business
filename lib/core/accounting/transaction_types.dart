/// Transaction type identifiers stored in SQLite.
abstract final class TransactionTypes {
  static const String sale = 'sale';
  static const String purchase = 'purchase';
  static const String paymentReceived = 'payment_received';
  static const String paymentPaid = 'payment_paid';
  static const String expense = 'expense';
  static const String journal = 'journal';
}
