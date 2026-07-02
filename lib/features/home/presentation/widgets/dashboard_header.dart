import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/branding/app_branding.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../utils/dashboard_greeting.dart';

/// Dashboard header — logo, business name, date and greeting.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.businessName,
    this.onProfileTap,
  });

  final String businessName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final greeting = DashboardGreeting.forTime();
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
              child: Image.asset(
                AppBranding.logoAssetPath,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  color: ColorPalette.purple.withValues(alpha: 0.08),
                  child: const Text(
                    'BT',
                    style: TextStyle(
                      color: ColorPalette.purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: BilingualLabel(
                english: 'Dashboard',
                hindi: 'Home',
                compact: true,
              ),
            ),
            if (onProfileTap != null)
              IconButton(
                tooltip: 'Business Profile',
                onPressed: onProfileTap,
                icon: const Icon(
                  Icons.storefront_rounded,
                  color: ColorPalette.iconPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          businessName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColorPalette.labelPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          DateFormatter.displayDate(today),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorPalette.labelSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        BilingualLabel(
          english: greeting.english,
          hindi: greeting.hindi,
          compact: true,
          englishStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorPalette.purple,
          ),
          hindiStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ColorPalette.purple,
          ),
        ),
      ],
    );
  }
}
