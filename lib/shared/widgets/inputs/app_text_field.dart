import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/theme/color_palette.dart';
import '../labels/app_form_field_label.dart';

/// Standard grouped text field — label, input, optional helper below field.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.english,
    required this.hindi,
    required this.controller,
    this.helper,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction,
    this.maxLines = 1,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.hintText,
  });

  final String english;
  final String hindi;
  final TextEditingController controller;
  final String? helper;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final int maxLines;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormFieldLabel(
          english: english,
          hindi: hindi,
          compact: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: context.appText.primary,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: ColorPalette.iconPrimary, size: 20),
            filled: true,
            fillColor: ColorPalette.cardSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
              borderSide: const BorderSide(color: ColorPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
              borderSide: const BorderSide(color: ColorPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
              borderSide: const BorderSide(
                color: ColorPalette.purple,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
              borderSide: const BorderSide(color: Color(0xFFFF3B30)),
            ),
          ),
        ),
        if (helper != null && helper!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper!,
            style: context.appText.helper,
          ),
        ],
      ],
    );
  }
}
