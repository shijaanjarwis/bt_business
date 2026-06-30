/// Aggregated business metrics for the home dashboard.
class DashboardSummary {
  const DashboardSummary({
    required this.todaysProfit,
    required this.todaysSales,
    required this.todaysPurchase,
    required this.todaysExpenses,
    required this.cashInHand,
    required this.amountInBank,
    required this.todaysReceivables,
    required this.todaysPayables,
    required this.paymentReceived,
    required this.paymentPaid,
    required this.goodsSold,
    required this.goodsPurchased,
    required this.stockValue,
    required this.receivableCount,
    required this.payableCount,
  });

  final double todaysProfit;
  final double todaysSales;
  final double todaysPurchase;
  final double todaysExpenses;
  final double cashInHand;
  final double amountInBank;
  final double todaysReceivables;
  final double todaysPayables;
  final double paymentReceived;
  final double paymentPaid;
  final double goodsSold;
  final double goodsPurchased;
  final double stockValue;
  final int receivableCount;
  final int payableCount;

  static const DashboardSummary zero = DashboardSummary(
    todaysProfit: 0,
    todaysSales: 0,
    todaysPurchase: 0,
    todaysExpenses: 0,
    cashInHand: 0,
    amountInBank: 0,
    todaysReceivables: 0,
    todaysPayables: 0,
    paymentReceived: 0,
    paymentPaid: 0,
    goodsSold: 0,
    goodsPurchased: 0,
    stockValue: 0,
    receivableCount: 0,
    payableCount: 0,
  );
}
