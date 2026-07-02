import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_spacing.dart';
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
        const SizedBox(height: AppSpacing.md),
        _QuickActionButton(
          english: 'Sale',
          hindi: 'Bikri Likho',
          icon: Icons.edit_note_rounded,
          color: ColorPalette.purple,
          onTap: () => context.push(RouteNames.salesNew),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickActionButton(
          english: 'Purchase',
          hindi: 'Kharid Likho',
          icon: Icons.shopping_bag_outlined,
          color: ColorPalette.accentBlue,
          onTap: () => context.push(RouteNames.purchasesNew),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickActionButton(
          english: 'Receive',
          hindi: 'Paise Mile',
          icon: Icons.call_received_rounded,
          color: ColorPalette.accentGreen,
          onTap: () => context.push(RouteNames.paymentsReceived),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickActionButton(
          english: 'Payment',
          hindi: 'Paise Diye',
          icon: Icons.call_made_rounded,
          color: ColorPalette.accentOrange,
          onTap: () => context.push(RouteNames.paymentsPaid),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickActionButton(
          english: 'Expense',
          hindi: 'Kharcha Likho',
          icon: Icons.receipt_long_outlined,
          color: ColorPalette.labelPrimary,
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
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: ColorPalette.border),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
                ),
                child: Icon(icon, color: color, size: AppDimensions.iconSize),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: BilingualLabel(
                  english: english,
                  hindi: hindi,
                  compact: true,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColorPalette.iconPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
