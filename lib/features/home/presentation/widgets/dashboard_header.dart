import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/branding/app_branding.dart';
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
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                AppBranding.logoAssetPath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => Container(
                  width: 40,
                  height: 40,
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
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                AppBranding.appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: Color(0xFF1C1C1E),
                  height: 1.1,
                ),
              ),
            ),
            if (onProfileTap != null)
              IconButton(
                tooltip: 'Business Profile',
                onPressed: onProfileTap,
                icon: const Icon(
                  Icons.storefront_rounded,
                  color: ColorPalette.purple,
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          businessName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormatter.displayDate(today),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorPalette.labelSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${greeting.hindi} · ${greeting.english}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorPalette.purple,
          ),
        ),
      ],
    );
  }
}
