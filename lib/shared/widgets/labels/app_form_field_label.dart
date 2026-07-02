import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/color_palette.dart';
import 'bilingual_label.dart';

/// Standard form label block — English title, Hindi subtitle, optional helper below.
class AppFormFieldLabel extends StatelessWidget {
  const AppFormFieldLabel({
    super.key,
    required this.english,
    required this.hindi,
    this.helper,
    this.compact = false,
  });

  final String english;
  final String hindi;
  final String? helper;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualLabel(
          english: english,
          hindi: hindi,
          compact: compact,
        ),
        if (helper != null && helper!.isNotEmpty) ...[
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            helper!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ColorPalette.labelSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
