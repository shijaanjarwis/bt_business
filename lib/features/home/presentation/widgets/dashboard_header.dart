import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/dashboard_greeting_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/branding/app_branding.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import 'dashboard_greeting_text.dart';

/// Dashboard header — logo, business name, date and greeting.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    super.key,
    required this.businessName,
    this.onProfileTap,
  });

  final String businessName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final greeting = ref.watch(dashboardGreetingDisplayProvider);

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
            Expanded(
              child: BilingualLabel.fromKey('dashboard', compact: true),
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
        const SizedBox(height: AppSpacing.md),
        DashboardGreetingText(display: greeting),
      ],
    );
  }
}
