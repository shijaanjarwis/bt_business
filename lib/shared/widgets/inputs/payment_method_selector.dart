import 'package:flutter/material.dart';

import '../../../core/accounting/payment_method_channel.dart';
import '../../../core/theme/color_palette.dart';

/// Selectable Cash / UPI / Bank chips for payment entry screens.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethodChannel selected;
  final ValueChanged<PaymentMethodChannel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < PaymentMethodChannel.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _MethodChip(
              label: PaymentMethodChannel.values[i].label,
              selected: PaymentMethodChannel.values[i] == selected,
              onTap: () => onChanged(PaymentMethodChannel.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? ColorPalette.purple.withValues(alpha: 0.12)
                : ColorPalette.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? ColorPalette.purple.withValues(alpha: 0.45)
                  : ColorPalette.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? ColorPalette.purple : ColorPalette.labelPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
