import 'package:flutter/material.dart';

import '../layout/main_shell_insets.dart';
import 'global_plus_fab.dart';
import 'global_voice_fab.dart';

/// Stacked global FABs — add above voice, fixed spacing.
class GlobalFabStack extends StatelessWidget {
  const GlobalFabStack({
    super.key,
    required this.onPlusPressed,
    this.onVoicePressed,
  });

  final VoidCallback onPlusPressed;
  final VoidCallback? onVoicePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlobalPlusFab(onPressed: onPlusPressed),
        const SizedBox(height: MainShellInsets.fabStackSpacing),
        GlobalVoiceFab(onPressed: onVoicePressed),
      ],
    );
  }
}
