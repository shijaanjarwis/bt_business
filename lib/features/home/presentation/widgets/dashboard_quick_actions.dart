import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';

/// Large quick-action buttons for daily register work.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BilingualLabel(
          english: 'Quick Actions',
          hindi: 'Jaldi Kaam',
          compact: true,
        ),
        const SizedBox(height: 12),
        _QuickActionButton(
          english: 'Sell',
          hindi: 'Maal Becha',
          icon: Icons.edit_note_rounded,
          color: ColorPalette.purple,
          onTap: () => context.push(RouteNames.salesNew),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          english: 'Purchase',
          hindi: 'Maal Kharida',
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF007AFF),
          onTap: () => context.push(RouteNames.purchasesNew),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          english: 'Cash Received',
          hindi: 'Paise Mile',
          icon: Icons.call_received_rounded,
          color: const Color(0xFF34C759),
          onTap: () => context.push(RouteNames.paymentsReceived),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          english: 'Payment',
          hindi: 'Paise Diya',
          icon: Icons.call_made_rounded,
          color: const Color(0xFFFF9500),
          onTap: () => context.push(RouteNames.paymentsPaid),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          english: 'Expense',
          hindi: 'Kharcha',
          icon: Icons.receipt_long_rounded,
          color: ColorPalette.labelSecondary,
          onTap: () => context.push(RouteNames.paymentsExpense),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.english,
    required this.hindi,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String english;
  final String hindi;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E5EA)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: BilingualLabel(
                  english: english,
                  hindi: hindi,
                  compact: true,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
