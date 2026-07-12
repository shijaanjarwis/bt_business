import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';

/// First-install prompt — enable automatic backup after business profile setup.
class AutoBackupSetupDialog extends StatelessWidget {
  const AutoBackupSetupDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return AppDialog.show<bool>(
      context,
      barrierDismissible: false,
      child: const AutoBackupSetupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog.shell(
      context: context,
      icon: const Icon(
        Icons.shield_outlined,
        color: ColorPalette.purple,
        size: 32,
      ),
      title: 'Automatic Copy Chalu Karein?',
      message:
          'Roz raat 2 baje phone charge aur WiFi par aapka poora hisaab '
          'iCloud / Google Drive par save ho jayega.\n\n'
          'Ye bahut zaroori hai — data safe rahega.',
      actions: [
        AppDialog.action(
          context: context,
          label: 'Baad Mein',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppDialog.filledAction(
          context: context,
          label: 'Haan, Chalu Karein',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
