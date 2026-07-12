import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/color_palette.dart';
import '../labels/bilingual_label.dart';
import 'app_bottom_sheet.dart';

/// Direct entry routes from history register FAB — one tap per entry type.
class AppQuickEntrySheet {
  AppQuickEntrySheet._();

  static Future<void> show(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) {
        return AppBottomSheetLayout(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BilingualLabel(
                english: 'New Entry',
                hindi: 'Nayi Entry',
                compact: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              _EntryTile(
                english: 'Sale',
                hindi: 'Bikri Likho',
                icon: Icons.receipt_long_outlined,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.salesNew);
                },
              ),
              _EntryTile(
                english: 'Purchase',
                hindi: 'Kharid Likho',
                icon: Icons.shopping_bag_outlined,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.purchasesNew);
                },
              ),
              _EntryTile(
                english: 'Receive',
                hindi: 'Paise Mile',
                icon: Icons.call_received_rounded,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.paymentsReceived);
                },
              ),
              _EntryTile(
                english: 'Payment',
                hindi: 'Paise Diye',
                icon: Icons.call_made_rounded,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.paymentsPaid);
                },
              ),
              _EntryTile(
                english: 'Expense',
                hindi: 'Kharcha Likho',
                icon: Icons.receipt_outlined,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.paymentsExpense);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.english,
    required this.hindi,
    required this.icon,
    required this.onTap,
  });

  final String english;
  final String hindi;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: ColorPalette.background,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: ColorPalette.iconPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: BilingualLabel(
                    english: english,
                    hindi: hindi,
                    compact: true,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ColorPalette.iconPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
