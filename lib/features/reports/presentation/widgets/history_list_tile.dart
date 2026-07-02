import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/transaction_badge_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/badges/app_transaction_badge.dart';
import '../../data/datasources/transaction_history_local_datasource.dart';
import '../utils/history_ui_helpers.dart';

class HistoryListTile extends StatelessWidget {
  const HistoryListTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final TransactionHistoryEntry entry;
  final VoidCallback onTap;

  static final _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final badgeKind = TransactionBadgeKind.fromTransactionType(entry.type);
    final showAmount = HistoryUiHelpers.showAmountFor(entry);
    final partyName = entry.partyName?.trim();
    final subtitle = HistoryUiHelpers.typeLabel(entry);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeKind.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  HistoryUiHelpers.iconFor(entry),
                  color: badgeKind.foregroundColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partyName?.isNotEmpty == true ? partyName! : subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.labelPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppTransactionBadge(kind: badgeKind, compact: true),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormatter.shortDate(entry.date)} · ${_timeFormat.format(entry.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorPalette.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showAmount) ...[
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(entry.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.purple,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
