/// Aggregated daily business metrics for the home dashboard.
class DashboardSummary {
  const DashboardSummary({
    this.todaysProfit = 0,
    this.todaysSales = 0,
    this.todaysPurchase = 0,
    this.cashInHand = 0,
    this.amountInBank = 0,
    this.todaysReceivables = 0,
    this.todaysPayables = 0,
    this.paymentReceived = 0,
    this.paymentPaid = 0,
    this.goodsSold = 0,
    this.goodsPurchased = 0,
    this.receivableCount = 0,
    this.payableCount = 0,
  });

  final double todaysProfit;
  final double todaysSales;
  final double todaysPurchase;
  final double cashInHand;
  final double amountInBank;
  final double todaysReceivables;
  final double todaysPayables;
  final double paymentReceived;
  final double paymentPaid;
  final double goodsSold;
  final double goodsPurchased;
  final int receivableCount;
  final int payableCount;

  DashboardSummary copyWith({
    double? todaysProfit,
    double? todaysSales,
    double? todaysPurchase,
    double? cashInHand,
    double? amountInBank,
    double? todaysReceivables,
    double? todaysPayables,
    double? paymentReceived,
    double? paymentPaid,
    double? goodsSold,
    double? goodsPurchased,
    int? receivableCount,
    int? payableCount,
  }) {
    return DashboardSummary(
      todaysProfit: todaysProfit ?? this.todaysProfit,
      todaysSales: todaysSales ?? this.todaysSales,
      todaysPurchase: todaysPurchase ?? this.todaysPurchase,
      cashInHand: cashInHand ?? this.cashInHand,
      amountInBank: amountInBank ?? this.amountInBank,
      todaysReceivables: todaysReceivables ?? this.todaysReceivables,
      todaysPayables: todaysPayables ?? this.todaysPayables,
      paymentReceived: paymentReceived ?? this.paymentReceived,
      paymentPaid: paymentPaid ?? this.paymentPaid,
      goodsSold: goodsSold ?? this.goodsSold,
      goodsPurchased: goodsPurchased ?? this.goodsPurchased,
      receivableCount: receivableCount ?? this.receivableCount,
      payableCount: payableCount ?? this.payableCount,
    );
  }
}
