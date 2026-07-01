import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/party.dart';
import '../utils/party_ledger_ui_helpers.dart';

class PartyListTile extends StatelessWidget {
  const PartyListTile({
    super.key,
    required this.party,
    required this.onTap,
    this.lastActivity,
  });

  final Party party;
  final VoidCallback onTap;
  final DateTime? lastActivity;

  @override
  Widget build(BuildContext context) {
    final status = PartyLedgerUiHelpers.balanceStatus(party);

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    if (party.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        party.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF636366),
                        ),
                      ),
                    ],
                    if (lastActivity != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Aakhri: ${DateFormatter.shortDate(lastActivity!)} · ${DateFormat('h:mm a').format(lastActivity!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    PartyLedgerUiHelpers.formattedBalance(party),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: status.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
