import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../layout/main_shell_insets.dart';

/// App-wide add FAB — circular "+" button only.
class GlobalPlusFab extends StatelessWidget {
  const GlobalPlusFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const double diameter = MainShellInsets.fabDiameter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: FloatingActionButton(
        heroTag: 'bt_global_plus_fab',
        onPressed: onPressed,
        backgroundColor: ColorPalette.purple,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: const CircleBorder(),
        tooltip: 'Add',
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}
