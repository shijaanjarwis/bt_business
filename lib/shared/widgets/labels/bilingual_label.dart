import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';

/// English heading with simple Hindi subtitle in parentheses on the line below.
class BilingualLabel extends StatelessWidget {
  const BilingualLabel({
    super.key,
    required this.english,
    required this.hindi,
    this.englishStyle,
    this.hindiStyle,
    this.compact = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String english;
  final String hindi;
  final TextStyle? englishStyle;
  final TextStyle? hindiStyle;
  final bool compact;
  final CrossAxisAlignment crossAxisAlignment;

  String get _hindiLine {
    final trimmed = hindi.trim();
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      return trimmed;
    }
    return '($trimmed)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          english,
          style: englishStyle ??
              theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ColorPalette.labelPrimary,
                letterSpacing: -0.2,
                fontSize: compact ? 14 : 16,
                height: 1.2,
              ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          _hindiLine,
          style: hindiStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: ColorPalette.hindiText,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}
