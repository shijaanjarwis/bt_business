import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../layout/main_shell_insets.dart';

/// Single app-wide voice FAB — circular mic button, no label text.
class GlobalVoiceFab extends StatelessWidget {
  const GlobalVoiceFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  static const double diameter = MainShellInsets.fabDiameter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: FloatingActionButton(
        heroTag: 'bt_global_voice_fab',
        onPressed: onPressed ?? () => showComingSoon(context),
        backgroundColor: ColorPalette.purple,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: const CircleBorder(),
        tooltip: 'Voice',
        child: const Icon(Icons.mic_rounded, size: 26, color: Colors.white),
      ),
    );
  }

  static void showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Voice jald aa raha hai'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MainShellInsets.fabSnackBarBottom(context),
        ),
      ),
    );
  }
}
