import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../utils/purchase_ui_helpers.dart';

class PurchaseListTile extends StatelessWidget {
  const PurchaseListTile({
    super.key,
    required this.invoice,
    required this.onTap,
    this.defaultPartyId,
  });

  final PurchaseInvoice invoice;
  final VoidCallback onTap;
  final String? defaultPartyId;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(invoice.createdAt);
    final partyLabel = PurchaseUiHelpers.partyLabel(
      partyId: invoice.partyId,
      partyName: invoice.partyName,
      defaultPartyId: defaultPartyId,
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
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(invoice.grandTotal),
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
                    label: 'Diya',
                    value: CurrencyFormatter.format(invoice.paidAmount),
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'Baaki',
                    value: CurrencyFormatter.format(invoice.dueAmount),
                    color: invoice.dueAmount > 0
                        ? Colors.orange.shade800
                        : const Color(0xFF636366),
                  ),
                  const Spacer(),
                  Text(
                    '${DateFormatter.shortDate(invoice.date)} · $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF636366),
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
