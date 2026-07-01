import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/accounting/transaction_types.dart';
import 'party_history_entry.dart';

/// Builds notebook-style running balance from raw transaction rows.
abstract final class PartyHistoryBuilder {
  static List<PartyHistoryEntry> build(List<PartyHistoryRawRow> rows) {
    final sorted = [...rows]
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.createdAt.compareTo(b.createdAt);
      });

    var running = 0.0;
    final entries = <PartyHistoryEntry>[];

    for (final row in sorted) {
      final delta = _balanceDelta(row);
      running += delta;
      entries.add(
        PartyHistoryEntry(
          id: row.id,
          date: row.date,
          createdAt: row.createdAt,
          kind: _kind(row),
          label: _label(row),
          amount: row.totalAmount,
          balanceDelta: delta,
          runningBalance: running,
        ),
      );
    }

    return entries;
  }

  static double _balanceDelta(PartyHistoryRawRow row) {
    if (row.type == TransactionTypes.journal &&
        row.notes == 'Opening balance') {
      return row.totalAmount * (row.isReceivableOpening ? 1 : -1);
    }

    return switch (row.type) {
      TransactionTypes.sale =>
        row.paymentMode == PaymentMode.credit ? row.totalAmount : 0,
      TransactionTypes.purchase =>
        row.paymentMode == PaymentMode.credit ? -row.totalAmount : 0,
      TransactionTypes.paymentReceived => -row.totalAmount,
      TransactionTypes.paymentPaid => row.totalAmount,
      _ => 0,
    };
  }

  static PartyHistoryKind _kind(PartyHistoryRawRow row) {
    if (row.type == TransactionTypes.journal &&
        row.notes == 'Opening balance') {
      return PartyHistoryKind.opening;
    }
    return switch (row.type) {
      TransactionTypes.sale => PartyHistoryKind.sale,
      TransactionTypes.purchase => PartyHistoryKind.purchase,
      TransactionTypes.paymentReceived => PartyHistoryKind.received,
      TransactionTypes.paymentPaid => PartyHistoryKind.paid,
      _ => PartyHistoryKind.opening,
    };
  }

  static String _label(PartyHistoryRawRow row) {
    if (row.type == TransactionTypes.journal &&
        row.notes == 'Opening balance') {
      return 'Pehle se baaki';
    }
    return switch (row.type) {
      TransactionTypes.sale => 'Bikri',
      TransactionTypes.purchase => 'Kharid',
      TransactionTypes.paymentReceived => 'Jama',
      TransactionTypes.paymentPaid => 'Paise Diye',
      _ => row.type,
    };
  }
}

/// Raw row from SQLite before notebook formatting.
class PartyHistoryRawRow {
  const PartyHistoryRawRow({
    required this.id,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentMode,
    required this.notes,
    required this.isReceivableOpening,
  });

  final String id;
  final String type;
  final DateTime date;
  final DateTime createdAt;
  final double totalAmount;
  final PaymentMode? paymentMode;
  final String? notes;
  final bool isReceivableOpening;
}
