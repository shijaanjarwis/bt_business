/// One row on a dashboard summary detail screen.
class DashboardSummaryEntry {
  const DashboardSummaryEntry({
    required this.id,
    required this.transactionType,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.subtitle,
    this.paidAmount,
    this.dueAmount,
    this.isReceive = false,
    this.isCashOut = false,
  });

  final String id;
  final String transactionType;
  final String title;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final String? subtitle;
  final double? paidAmount;
  final double? dueAmount;
  final bool isReceive;
  final bool isCashOut;
}
