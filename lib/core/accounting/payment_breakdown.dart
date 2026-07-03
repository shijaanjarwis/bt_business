import 'payment_modes.dart';

/// Split payment amounts for sale and purchase entries.
class PaymentBreakdown {
  const PaymentBreakdown({
    this.cash = 0,
    this.upi = 0,
    this.bank = 0,
    this.cheque = 0,
  });

  final double cash;
  final double upi;
  final double bank;
  final double cheque;

  double get paidTotal => cash + upi + bank + cheque;

  double remainingCredit(double grandTotal) =>
      (grandTotal - paidTotal).clamp(0, double.infinity);

  PaymentBreakdown clampToTotal(double grandTotal) {
    if (paidTotal <= grandTotal) return this;

    var remaining = grandTotal;
    final cashAmount = cash.clamp(0, remaining).toDouble();
    remaining -= cashAmount;
    final upiAmount = upi.clamp(0, remaining).toDouble();
    remaining -= upiAmount;
    final bankAmount = bank.clamp(0, remaining).toDouble();
    remaining -= bankAmount;
    final chequeAmount = cheque.clamp(0, remaining).toDouble();

    return PaymentBreakdown(
      cash: cashAmount,
      upi: upiAmount,
      bank: bankAmount,
      cheque: chequeAmount,
    );
  }

  /// Reads stored columns; falls back to legacy [paidAmount] as cash.
  static PaymentBreakdown fromStored({
    required double cashAmount,
    required double upiAmount,
    required double bankAmount,
    required double chequeAmount,
    required double paidAmount,
  }) {
    final breakdown = PaymentBreakdown(
      cash: cashAmount,
      upi: upiAmount,
      bank: bankAmount,
      cheque: chequeAmount,
    );
    if (breakdown.paidTotal > 0) return breakdown;
    if (paidAmount > 0) return PaymentBreakdown(cash: paidAmount);
    return const PaymentBreakdown();
  }

  /// Resolves stored breakdown, explicit paid amount, or legacy payment mode.
  static PaymentBreakdown resolve({
    required PaymentBreakdown breakdown,
    required PaymentMode paymentMode,
    required double grandTotal,
    double? paidAmount,
  }) {
    if (breakdown.paidTotal > 0) {
      return breakdown.clampToTotal(grandTotal);
    }
    if (paidAmount != null && paidAmount > 0) {
      return PaymentBreakdown(cash: paidAmount).clampToTotal(grandTotal);
    }
    if (paymentMode == PaymentMode.cash) {
      return PaymentBreakdown(cash: grandTotal);
    }
    return const PaymentBreakdown();
  }
}
