import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/color_palette.dart';
import '../labels/app_form_field_label.dart';

/// Tap-to-select field with bilingual label — no placeholder inside the box.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.english,
    required this.hindi,
    required this.value,
    required this.onTap,
    this.helper,
    this.emptyText = 'Tap to select',
    this.emptyHindi = 'Chunein',
    this.trailingIcon = Icons.chevron_right_rounded,
    this.onClear,
  });

  final String english;
  final String hindi;
  final String? value;
  final VoidCallback onTap;
  final String? helper;
  final String emptyText;
  final String emptyHindi;
  final IconData trailingIcon;
  final VoidCallback? onClear;

  bool get _hasValue => value != null && value!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormFieldLabel(
          english: english,
          hindi: hindi,
          helper: helper,
          compact: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: ColorPalette.cardSurface,
          borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
                border: Border.all(color: ColorPalette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _hasValue
                        ? Text(
                            value!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.labelPrimary,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emptyText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: ColorPalette.labelSecondary,
                                ),
                              ),
                              Text(
                                '($emptyHindi)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ColorPalette.labelSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (_hasValue && onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: AppDimensions.iconSizeSm,
                        color: ColorPalette.iconPrimary,
                      ),
                      tooltip: 'Clear',
                    ),
                  Icon(trailingIcon, color: ColorPalette.iconPrimary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
