import '../../../../core/accounting/transaction_types.dart';

/// One jama or paise diye row in the payment register.
class PaymentRegisterEntry {
  const PaymentRegisterEntry({
    required this.id,
    required this.type,
    required this.partyId,
    required this.partyName,
    required this.partyPhone,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String type;
  final String partyId;
  final String partyName;
  final String partyPhone;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final String? note;

  bool get isReceived => type == TransactionTypes.paymentReceived;
  bool get isPaid => type == TransactionTypes.paymentPaid;

  String get typeLabel => isReceived ? 'Paise Mile' : 'Paise Diya';
}
