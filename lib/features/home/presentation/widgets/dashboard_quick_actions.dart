import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';

/// Quick register entries from the dashboard — jama, payment, kharch.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BilingualLabel(
          english: 'Quick Write',
          hindi: 'Jaldi likho',
          compact: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickButton(
                icon: Icons.call_received_rounded,
                label: 'Jama',
                color: const Color(0xFF34C759),
                onTap: () => context.push(RouteNames.paymentsReceived),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickButton(
                icon: Icons.call_made_rounded,
                label: 'Paise Diye',
                color: Colors.orange.shade700,
                onTap: () => context.push(RouteNames.paymentsPaid),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickButton(
                icon: Icons.receipt_long_rounded,
                label: 'Kharch',
                color: ColorPalette.purple,
                onTap: () => context.push(RouteNames.paymentsExpense),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
