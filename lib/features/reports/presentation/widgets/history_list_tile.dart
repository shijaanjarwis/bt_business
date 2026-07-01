import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
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
    final typeColor = HistoryUiHelpers.colorFor(entry);
    final typeLabel = HistoryUiHelpers.typeLabel(entry);
    final showAmount = HistoryUiHelpers.showAmountFor(entry);
    final partyName = entry.partyName?.trim();

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
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  HistoryUiHelpers.iconFor(entry),
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partyName?.isNotEmpty == true ? partyName! : typeLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    if (partyName?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormatter.shortDate(entry.date)} · ${_timeFormat.format(entry.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorPalette.labelTertiary,
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
