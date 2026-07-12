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

  static const Color lightUnselectedBackground = Color(0xFFFFFFFF);
  static const Color lightUnselectedBorder = Color(0xFFD1D5DB);
  static const Color lightUnselectedText = Color(0xFF374151);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final unselectedBackground = isDark
        ? colorScheme.surfaceContainerHighest
        : lightUnselectedBackground;
    final unselectedBorder =
        isDark ? colorScheme.outlineVariant : lightUnselectedBorder;
    final unselectedText = isDark ? colorScheme.onSurface : lightUnselectedText;
    final selectedBackground = isDark ? colorScheme.primary : ColorPalette.purple;
    final selectedForeground =
        isDark ? colorScheme.onPrimary : Colors.white;
    final selectedCheck =
        isDark ? colorScheme.onPrimary : ColorPalette.purpleLight;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? selectedForeground : unselectedText,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: selected,
      backgroundColor: unselectedBackground,
      selectedColor: selectedBackground,
      disabledColor: unselectedBackground,
      checkmarkColor: selectedCheck,
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(
        color: selected ? selectedBackground : unselectedBorder,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
      ),
    );
  }
}
