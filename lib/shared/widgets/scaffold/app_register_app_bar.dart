import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../labels/bilingual_label.dart';

/// Standard register / form AppBar with bilingual title.
class AppRegisterAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppRegisterAppBar({
    super.key,
    required this.english,
    required this.hindi,
    this.actions,
    this.leading,
  });

  final String english;
  final String hindi;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorPalette.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: ColorPalette.iconPrimary,
      iconTheme: const IconThemeData(color: ColorPalette.iconPrimary),
      leading: leading,
      title: BilingualLabel(
        english: english,
        hindi: hindi,
        compact: true,
      ),
      actions: actions,
    );
  }
}
