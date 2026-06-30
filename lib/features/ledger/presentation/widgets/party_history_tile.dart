import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/party_history_entry.dart';

class PartyHistoryTile extends StatelessWidget {
  const PartyHistoryTile({
    super.key,
    required this.entry,
  });

  final PartyHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final balanceColor = entry.runningBalance > 0
        ? const Color(0xFF34C759)
        : entry.runningBalance < 0
            ? const Color(0xFFFF3B30)
            : const Color(0xFF8E8E93);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              DateFormatter.shortDate(entry.date),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.label} ${CurrencyFormatter.format(entry.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Baaki ${CurrencyFormatter.format(entry.runningBalance.abs())}'
                  '${entry.runningBalance > 0 ? ' lena' : entry.runningBalance < 0 ? ' dena' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: balanceColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PartyHistoryDivider extends StatelessWidget {
  const PartyHistoryDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.black.withValues(alpha: 0.06));
  }
}
