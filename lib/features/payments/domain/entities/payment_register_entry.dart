import '../../../../core/accounting/payment_breakdown.dart';
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
    this.balanceAfterPayment,
    this.paymentBreakdown = const PaymentBreakdown(),
    this.reminderDate,
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
  final double? balanceAfterPayment;
  final PaymentBreakdown paymentBreakdown;
  final DateTime? reminderDate;

  String get paymentModeLabel {
    if (paymentBreakdown.upi > 0 &&
        paymentBreakdown.cash <= 0 &&
        paymentBreakdown.bank <= 0) {
      return 'UPI';
    }
    if (paymentBreakdown.bank > 0 &&
        paymentBreakdown.cash <= 0 &&
        paymentBreakdown.upi <= 0) {
      return 'Bank';
    }
    return 'Cash';
  }

  bool get isPending => reminderDate != null;

  bool get isReceived => type == TransactionTypes.paymentReceived;
  bool get isPaid => type == TransactionTypes.paymentPaid;

  String get typeLabelEnglish => isReceived ? 'Receive' : 'Payment';
}
