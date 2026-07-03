import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/opening_balance_direction.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_history_entry.dart';
import '../providers/party_providers.dart';

/// Totals derived from a party's transaction history.
class PartyHistoryStats {
  const PartyHistoryStats({
    required this.totalSale,
    required this.totalPurchase,
    required this.totalReceived,
    required this.totalPaid,
    this.lastEntry,
  });

  final double totalSale;
  final double totalPurchase;
  final double totalReceived;
  final double totalPaid;
  final PartyHistoryEntry? lastEntry;
}

/// Presentation helpers for Hisaab screens.
abstract final class PartyLedgerUiHelpers {
  static ({String label, Color color}) balanceStatus(Party party) {
    final amount = party.balance.abs();
    if (amount == 0) {
      return (label: 'Saaf Hisaab', color: ColorPalette.labelTertiary);
    }
    if (party.isReceivable) {
      return (label: 'Lena Hai', color: const Color(0xFF34C759));
    }
    return (label: 'Dena Hai', color: const Color(0xFFFF3B30));
  }

  static String formattedBalance(Party party) {
    return CurrencyFormatter.format(party.balance.abs());
  }

  static bool matchesFilter(Party party, PartyBalanceFilter filter) {
    return switch (filter) {
      PartyBalanceFilter.all => true,
      PartyBalanceFilter.lena => party.isReceivable,
      PartyBalanceFilter.dena => party.isPayable,
      PartyBalanceFilter.saaf => party.balance.abs() == 0,
    };
  }

  static String historyTypeLabel(PartyHistoryKind kind) {
    return switch (kind) {
      PartyHistoryKind.opening => 'Pehle se baaki',
      PartyHistoryKind.sale => 'Bikri',
      PartyHistoryKind.purchase => 'Kharid',
      PartyHistoryKind.received => 'Paise Mile',
      PartyHistoryKind.paid => 'Paise Diya',
    };
  }

  static Color runningBalanceColor(double runningBalance) {
    if (runningBalance > 0) return const Color(0xFF34C759);
    if (runningBalance < 0) return const Color(0xFFFF3B30);
    return ColorPalette.labelTertiary;
  }

  static String runningBalanceLabel(double runningBalance) {
    final amount = CurrencyFormatter.format(runningBalance.abs());
    if (runningBalance > 0) return '$amount lena';
    if (runningBalance < 0) return '$amount dena';
    return 'Saaf';
  }

  static String openingBalanceLabel(Party party) {
    if (party.openingAmount == 0) return '—';
    final amount = CurrencyFormatter.format(party.openingAmount);
    return party.openingDirection == OpeningBalanceDirection.receivable
        ? '$amount lena'
        : '$amount dena';
  }

  static PartyHistoryStats statsFrom(List<PartyHistoryEntry> entries) {
    var totalSale = 0.0;
    var totalPurchase = 0.0;
    var totalReceived = 0.0;
    var totalPaid = 0.0;
    PartyHistoryEntry? lastEntry;

    for (final entry in entries) {
      switch (entry.kind) {
        case PartyHistoryKind.sale:
          totalSale += entry.amount;
        case PartyHistoryKind.purchase:
          totalPurchase += entry.amount;
        case PartyHistoryKind.received:
          totalReceived += entry.amount;
        case PartyHistoryKind.paid:
          totalPaid += entry.amount;
        case PartyHistoryKind.opening:
          break;
      }
    }

    for (final entry in entries.reversed) {
      if (entry.kind != PartyHistoryKind.opening) {
        lastEntry = entry;
        break;
      }
    }

    return PartyHistoryStats(
      totalSale: totalSale,
      totalPurchase: totalPurchase,
      totalReceived: totalReceived,
      totalPaid: totalPaid,
      lastEntry: lastEntry,
    );
  }

  static String lastTransactionLabel(PartyHistoryEntry entry) {
    final type = historyTypeLabel(entry.kind);
    return '$type · ${DateFormatter.displayDate(entry.date)} · ${CurrencyFormatter.format(entry.amount)}';
  }
}
