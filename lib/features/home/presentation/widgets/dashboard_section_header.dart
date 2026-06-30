import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

/// Section divider label for grouped dashboard cards.
class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ColorPalette.labelSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
