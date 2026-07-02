import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/color_palette.dart';

/// Shared filter chip styling for registers and ledgers.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? ColorPalette.purple : ColorPalette.labelPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: ColorPalette.purple.withValues(alpha: 0.14),
      checkmarkColor: ColorPalette.purple,
      side: BorderSide(
        color: selected ? ColorPalette.purple.withValues(alpha: 0.35) : ColorPalette.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
      ),
    );
  }
}
