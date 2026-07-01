/// The four register metrics always computed from transactions — never stored.
class DashboardCoreMetrics {
  const DashboardCoreMetrics({
    required this.aajKiBikri,
    required this.aajCashMila,
    required this.aajUdhaarBana,
    required this.cashInHand,
  });

  /// Total value of all sale entries on the given day.
  final double aajKiBikri;

  /// All cash received today from every source (sales, jama, etc.).
  final double aajCashMila;

  /// Remaining udhaar created on today's sale entries.
  final double aajUdhaarBana;

  /// Net cash position: all cash in − all cash out (+ optional opening cash).
  final double cashInHand;

  static const DashboardCoreMetrics zero = DashboardCoreMetrics(
    aajKiBikri: 0,
    aajCashMila: 0,
    aajUdhaarBana: 0,
    cashInHand: 0,
  );
}
