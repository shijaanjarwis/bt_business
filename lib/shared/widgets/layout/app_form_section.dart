import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/color_palette.dart';
import '../labels/bilingual_label.dart';

/// Grouped form section with bilingual heading and card container.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.english,
    required this.hindi,
    required this.child,
    this.helper,
  });

  final String english;
  final String hindi;
  final Widget child;
  final String? helper;

  /// Legacy single-line title — maps to english with empty hindi helper line hidden.
  factory AppFormSection.legacyTitle({
    required String title,
    required Widget child,
  }) {
    return AppFormSection(
      english: title,
      hindi: title,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualLabel(
          english: english,
          hindi: hindi,
          compact: true,
        ),
        if (helper != null && helper!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ColorPalette.labelSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: ColorPalette.cardSurface,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(color: ColorPalette.border),
          ),
          child: child,
        ),
      ],
    );
  }
}
