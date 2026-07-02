import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/local/database/seeders/cash_customer_seeder.dart';
import '../../data/datasources/transaction_history_local_datasource.dart';
import '../../domain/history_models.dart';

/// Register-style labels, icons, grouping and search for history UI.
abstract final class HistoryUiHelpers {
  static String typeLabelEnglish(TransactionHistoryEntry entry) {
    if (entry.type == HistoryEntryTypes.partyCreated) return 'Party Added';
    if (entry.type == HistoryEntryTypes.partyUpdated) return 'Party Updated';
    return switch (entry.type) {
      TransactionTypes.paymentPaid => 'Payment',
      TransactionTypes.paymentReceived => 'Receive',
      TransactionTypes.sale => 'Sale',
      TransactionTypes.purchase => 'Purchase',
      TransactionTypes.expense => entry.label,
      _ => entry.label,
    };
  }

  static String displayPartyTitle(TransactionHistoryEntry entry) {
    final partyName = entry.partyName?.trim();
    if (partyName == null || partyName.isEmpty) {
      return typeLabelEnglish(entry);
    }
    if (partyName == CashCustomerSeeder.displayName) {
      return switch (entry.type) {
        TransactionTypes.sale => 'Cash Sale',
        TransactionTypes.purchase => 'Cash Purchase',
        _ => partyName,
      };
    }
    return partyName;
  }

  static String typeLabel(TransactionHistoryEntry entry) {
    if (entry.type == HistoryEntryTypes.partyCreated) return 'Naam Joda';
    if (entry.type == HistoryEntryTypes.partyUpdated) return 'Naam Badla';
    return switch (entry.type) {
      TransactionTypes.paymentPaid => 'Paise Diya',
      TransactionTypes.paymentReceived => 'Receive',
      TransactionTypes.sale => 'Bikri',
      TransactionTypes.purchase => 'Kharid',
      TransactionTypes.expense => entry.label,
      _ => entry.label,
    };
  }

  static IconData iconFor(TransactionHistoryEntry entry) {
    return switch (entry.type) {
      TransactionTypes.sale => Icons.sell_outlined,
      TransactionTypes.purchase => Icons.shopping_bag_outlined,
      TransactionTypes.paymentReceived => Icons.call_received_rounded,
      TransactionTypes.paymentPaid => Icons.call_made_rounded,
      TransactionTypes.expense => Icons.receipt_long_outlined,
      HistoryEntryTypes.partyCreated => Icons.person_add_alt_1_outlined,
      HistoryEntryTypes.partyUpdated => Icons.edit_outlined,
      _ => Icons.description_outlined,
    };
  }

  static Color colorFor(TransactionHistoryEntry entry) {
    return switch (entry.type) {
      TransactionTypes.sale => ColorPalette.purple,
      TransactionTypes.purchase => const Color(0xFF5856D6),
      TransactionTypes.paymentReceived => const Color(0xFF34C759),
      TransactionTypes.paymentPaid => const Color(0xFFFF9500),
      TransactionTypes.expense => ColorPalette.labelTertiary,
      HistoryEntryTypes.partyCreated => const Color(0xFF007AFF),
      HistoryEntryTypes.partyUpdated => const Color(0xFF007AFF),
      _ => ColorPalette.purple,
    };
  }

  static String dateHeader(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Aaj';
    if (day == today.subtract(const Duration(days: 1))) return 'Kal';
    return DateFormatter.shortDate(date);
  }

  static List<({String header, DateTime day, List<TransactionHistoryEntry> entries})>
      groupByDate(
    List<TransactionHistoryEntry> entries, {
    DateTime? now,
  }) {
    if (entries.isEmpty) return const [];

    final buckets = <DateTime, List<TransactionHistoryEntry>>{};
    for (final entry in entries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      buckets.putIfAbsent(day, () => []).add(entry);
    }

    final days = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in days)
        (
          header: dateHeader(day, now: now),
          day: day,
          entries: buckets[day]!
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        ),
    ];
  }

  static bool matchesSearch(TransactionHistoryEntry entry, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final typeLabel = typeLabelForSearch(entry).toLowerCase();
    final party = (entry.partyName ?? '').toLowerCase();
    final amountText = CurrencyFormatter.format(entry.amount).toLowerCase();
    final amountPlain = entry.amount.toStringAsFixed(0);
    final dateText = DateFormatter.shortDate(entry.date).toLowerCase();
    final timeText = DateFormat('h:mm a').format(entry.createdAt).toLowerCase();

    return typeLabel.contains(query) ||
        party.contains(query) ||
        amountText.contains(query) ||
        amountPlain.contains(query) ||
        dateText.contains(query) ||
        timeText.contains(query);
  }

  static String typeLabelForSearch(TransactionHistoryEntry entry) {
    if (entry.type == HistoryEntryTypes.partyCreated) {
      return 'party created naam joda';
    }
    if (entry.type == HistoryEntryTypes.partyUpdated) {
      return 'party updated naam badla';
    }
    return '${typeLabel(entry)} ${TransactionHistoryLabels.forType(entry.type, notes: entry.note)}';
  }

  static bool showAmountFor(TransactionHistoryEntry entry) {
    if (entry.type == HistoryEntryTypes.partyCreated ||
        entry.type == HistoryEntryTypes.partyUpdated) {
      return entry.amount > 0;
    }
    return true;
  }
}
