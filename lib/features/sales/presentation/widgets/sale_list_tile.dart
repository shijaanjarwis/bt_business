import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/sale_entry.dart';
import '../utils/sale_ui_helpers.dart';

class SaleListTile extends StatelessWidget {
  const SaleListTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.cashCustomerPartyId,
  });

  final SaleEntry entry;
  final VoidCallback onTap;
  final String? cashCustomerPartyId;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(entry.createdAt);
    final partyLabel = SaleUiHelpers.partyLabel(
      partyId: entry.partyId,
      partyName: entry.partyName,
      cashCustomerPartyId: cashCustomerPartyId,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partyLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.labelPrimary,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(entry.grandTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetricChip(
                    label: 'Mila',
                    value: CurrencyFormatter.format(entry.paidAmount),
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'Baaki',
                    value: CurrencyFormatter.format(entry.dueAmount),
                    color: entry.dueAmount > 0
                        ? Colors.orange.shade800
                        : ColorPalette.labelSecondary,
                  ),
                  const Spacer(),
                  Text(
                    '${DateFormatter.shortDate(entry.date)} · $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorPalette.labelSecondary,
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
