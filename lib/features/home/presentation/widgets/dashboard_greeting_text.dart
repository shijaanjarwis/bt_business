import 'package:flutter/material.dart';

import '../../../../core/localization/dashboard_greeting.dart';
import '../../../../core/theme/color_palette.dart';

/// Purple bold dashboard greeting — primary line plus optional (subtitle).
class DashboardGreetingText extends StatelessWidget {
  const DashboardGreetingText({
    super.key,
    required this.display,
  });

  final DashboardGreetingDisplay display;

  @override
  Widget build(BuildContext context) {
    const primaryStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ColorPalette.purple,
      letterSpacing: 0.2,
      height: 1.35,
    );

    final secondary = display.secondary?.trim();
    if (secondary == null || secondary.isEmpty) {
      return Text(display.primary, style: primaryStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display.primary, style: primaryStyle),
        const SizedBox(height: 2),
        Text(
          '($secondary)',
          style: primaryStyle.copyWith(fontSize: 15),
        ),
      ],
    );
  }
}
