import 'package:bt_business/core/accounting/payment_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentBreakdown', () {
    test('remainingCredit equals total when no payment entered', () {
      const breakdown = PaymentBreakdown();
      expect(breakdown.remainingCredit(122500), 122500);
      expect(breakdown.paidTotal, 0);
    });

    test('remainingCredit updates with mixed payment', () {
      const breakdown = PaymentBreakdown(cash: 20000, upi: 50000, bank: 10000);
      expect(breakdown.remainingCredit(122500), 42500);
    });

    test('remainingCredit becomes zero when fully paid', () {
      const breakdown = PaymentBreakdown(cash: 50000, upi: 72500);
      expect(breakdown.remainingCredit(122500), 0);
    });

    test('resolve does not auto-fill cash for empty breakdown', () {
      final resolved = PaymentBreakdown.resolve(
        breakdown: const PaymentBreakdown(),
        grandTotal: 122500,
      );
      expect(resolved.paidTotal, 0);
      expect(resolved.remainingCredit(122500), 122500);
    });

    test('resolve keeps explicit mixed breakdown', () {
      final resolved = PaymentBreakdown.resolve(
        breakdown: const PaymentBreakdown(cash: 20000, upi: 50000, bank: 10000),
        grandTotal: 122500,
      );
      expect(resolved.cash, 20000);
      expect(resolved.upi, 50000);
      expect(resolved.bank, 10000);
      expect(resolved.remainingCredit(122500), 42500);
    });

    test('resolve rejects overpayment via clampToTotal', () {
      final resolved = PaymentBreakdown.resolve(
        breakdown: const PaymentBreakdown(cash: 100000, upi: 50000),
        grandTotal: 122500,
      );
      expect(resolved.paidTotal, 122500);
      expect(resolved.remainingCredit(122500), 0);
    });
  });
}
