/// One line on a party's hisaab notebook page.
enum PartyHistoryKind {
  opening,
  sale,
  purchase,
  received,
  paid,
}

class PartyHistoryEntry {
  const PartyHistoryEntry({
    required this.id,
    required this.date,
    required this.kind,
    required this.label,
    required this.amount,
    required this.balanceDelta,
    required this.runningBalance,
  });

  final String id;
  final DateTime date;
  final PartyHistoryKind kind;
  final String label;
  final double amount;
  final double balanceDelta;
  final double runningBalance;
}
