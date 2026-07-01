import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/party_history_entry.dart';
import '../utils/party_history_navigation.dart';
import '../utils/party_ledger_ui_helpers.dart';

class PartyHistoryTile extends StatelessWidget {
  const PartyHistoryTile({
    super.key,
    required this.entry,
    required this.partyId,
  });

  final PartyHistoryEntry entry;
  final String partyId;

  @override
  Widget build(BuildContext context) {
    final typeLabel = PartyLedgerUiHelpers.historyTypeLabel(entry.kind);
    final balanceColor = PartyLedgerUiHelpers.runningBalanceColor(entry.runningBalance);
    final balanceLabel = PartyLedgerUiHelpers.runningBalanceLabel(entry.runningBalance);
    final timeLabel = DateFormat('h:mm a').format(entry.createdAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPartyHistoryEntry(
          context,
          entry: entry,
          partyId: partyId,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(entry.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Baaki: $balanceLabel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${DateFormatter.shortDate(entry.date)}\n$timeLabel',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: ColorPalette.labelTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
