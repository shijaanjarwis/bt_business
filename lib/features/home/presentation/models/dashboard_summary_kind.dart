import '../models/dashboard_metric.dart';

/// Dashboard summary card destinations.
enum DashboardSummaryKind {
  todaySales,
  todayPurchase,
  todayCashReceived,
  todayCredit,
  cashInHand;

  static DashboardSummaryKind? fromRoute(String slug) {
    return switch (slug) {
      'today-sales' => DashboardSummaryKind.todaySales,
      'today-purchase' => DashboardSummaryKind.todayPurchase,
      'today-cash-received' => DashboardSummaryKind.todayCashReceived,
      'today-credit' => DashboardSummaryKind.todayCredit,
      'cash-in-hand' => DashboardSummaryKind.cashInHand,
      _ => null,
    };
  }

  static DashboardSummaryKind fromTarget(DashboardMetricTarget target) {
    return switch (target) {
      DashboardMetricTarget.todaySales => DashboardSummaryKind.todaySales,
      DashboardMetricTarget.todayPurchase => DashboardSummaryKind.todayPurchase,
      DashboardMetricTarget.todayCashReceived => DashboardSummaryKind.todayCashReceived,
      DashboardMetricTarget.todayCredit => DashboardSummaryKind.todayCredit,
      DashboardMetricTarget.cashInHand => DashboardSummaryKind.cashInHand,
    };
  }

  String get routeSlug => switch (this) {
        DashboardSummaryKind.todaySales => 'today-sales',
        DashboardSummaryKind.todayPurchase => 'today-purchase',
        DashboardSummaryKind.todayCashReceived => 'today-cash-received',
        DashboardSummaryKind.todayCredit => 'today-credit',
        DashboardSummaryKind.cashInHand => 'cash-in-hand',
      };

  String get englishTitle => switch (this) {
        DashboardSummaryKind.todaySales => "Today's Sale",
        DashboardSummaryKind.todayPurchase => "Today's Purchase",
        DashboardSummaryKind.todayCashReceived => "Today's Cash Received",
        DashboardSummaryKind.todayCredit => "Today's Credit",
        DashboardSummaryKind.cashInHand => 'Cash In Hand',
      };

  String get hindiTitle => switch (this) {
        DashboardSummaryKind.todaySales => 'Aaj Ki Bikri',
        DashboardSummaryKind.todayPurchase => 'Aaj Ki Kharid',
        DashboardSummaryKind.todayCashReceived => 'Aaj Cash Mila',
        DashboardSummaryKind.todayCredit => 'Aaj Udhaar Bana',
        DashboardSummaryKind.cashInHand => 'Haath Mein Cash',
      };

  bool get usesSaleEntries =>
      this == DashboardSummaryKind.todaySales ||
      this == DashboardSummaryKind.todayCredit;

  bool get usesPurchaseEntries => this == DashboardSummaryKind.todayPurchase;
}
