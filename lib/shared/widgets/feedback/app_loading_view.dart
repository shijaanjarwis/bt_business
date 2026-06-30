import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';

/// Reusable centered loading indicator matching brand styling.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: ColorPalette.purple,
        strokeWidth: 2.5,
      ),
    );
  }
}
