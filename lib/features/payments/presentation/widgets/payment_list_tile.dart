import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/payment_register_entry.dart';

class PaymentListTile extends StatelessWidget {
  const PaymentListTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final PaymentRegisterEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = entry.isReceived
        ? const Color(0xFF34C759)
        : const Color(0xFFFF9500);
    final timeLabel = DateFormat('h:mm a').format(entry.createdAt);

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
                      entry.partyName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    if (entry.partyPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.partyPhone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF636366),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(entry.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.purple,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormatter.shortDate(entry.date)} · $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
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
