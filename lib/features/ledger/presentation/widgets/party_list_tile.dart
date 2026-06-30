import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/party.dart';

class PartyListTile extends StatelessWidget {
  const PartyListTile({
    super.key,
    required this.party,
    required this.onTap,
  });

  final Party party;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balance = party.balance.abs();
    final isClear = balance == 0;
    final isLena = party.isReceivable;

    final label = isClear
        ? 'Clear'
        : isLena
            ? 'Lena Hai'
            : 'Dena Hai';
    final balanceColor = isClear
        ? const Color(0xFF8E8E93)
        : isLena
            ? const Color(0xFF34C759)
            : const Color(0xFFFF3B30);

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
                        fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isClear)
                    Text(
                      CurrencyFormatter.format(balance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: balanceColor,
                      ),
                    ),
                  if (!isClear) const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: balanceColor,
                      fontWeight: FontWeight.w600,
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
