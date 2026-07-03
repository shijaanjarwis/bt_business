import 'payment_breakdown.dart';

/// Single payment channel — expandable to split payments later.
enum PaymentMethodChannel {
  cash,
  upi,
  bank;

  String get label => switch (this) {
        PaymentMethodChannel.cash => 'Cash',
        PaymentMethodChannel.upi => 'UPI',
        PaymentMethodChannel.bank => 'Bank',
      };

  PaymentBreakdown toBreakdown(double amount) {
    return switch (this) {
      PaymentMethodChannel.cash => PaymentBreakdown(cash: amount),
      PaymentMethodChannel.upi => PaymentBreakdown(upi: amount),
      PaymentMethodChannel.bank => PaymentBreakdown(bank: amount),
    };
  }

  static PaymentMethodChannel fromBreakdown(PaymentBreakdown breakdown) {
    if (breakdown.upi > 0 && breakdown.cash <= 0 && breakdown.bank <= 0) {
      return PaymentMethodChannel.upi;
    }
    if (breakdown.bank > 0 && breakdown.cash <= 0 && breakdown.upi <= 0) {
      return PaymentMethodChannel.bank;
    }
    return PaymentMethodChannel.cash;
  }
}
