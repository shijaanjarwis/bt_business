import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/color_palette.dart';
import '../labels/bilingual_label.dart';

/// Large bottom-right FAB for register screens — direct entry in one tap.
class AppRegisterFab extends StatelessWidget {
  const AppRegisterFab({
    super.key,
    required this.onPressed,
    required this.english,
    required this.hindi,
    this.icon = Icons.edit_note_rounded,
  });

  final VoidCallback onPressed;
  final String english;
  final String hindi;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: ColorPalette.purple,
      elevation: 4,
      icon: Icon(icon, size: AppDimensions.iconSize),
      label: BilingualLabel(
        english: english,
        hindi: hindi,
        compact: true,
        englishStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        hindiStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}
