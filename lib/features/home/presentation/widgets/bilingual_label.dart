import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

/// English heading with daily spoken Hindi subtitle in parentheses.
class BilingualLabel extends StatelessWidget {
  const BilingualLabel({
    super.key,
    required this.english,
    required this.hindi,
    this.englishStyle,
    this.hindiStyle,
    this.compact = false,
  });

  final String english;
  final String hindi;
  final TextStyle? englishStyle;
  final TextStyle? hindiStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          english,
          style: englishStyle ??
              theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
                letterSpacing: -0.2,
                fontSize: compact ? 13 : 15,
                height: 1.2,
              ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          '($hindi)',
          style: hindiStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: ColorPalette.hindiText,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}
