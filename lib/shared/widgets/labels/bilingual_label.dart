import 'package:flutter/material.dart';

/// English heading with simple Hindi subtitle on the line below.
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
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
                letterSpacing: -0.2,
                fontSize: compact ? 14 : 16,
                height: 1.2,
              ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          hindi,
          style: hindiStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF48484A),
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}
