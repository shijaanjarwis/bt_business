import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

/// First-install prompt — enable automatic backup after business profile setup.
class AutoBackupSetupDialog extends StatelessWidget {
  const AutoBackupSetupDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AutoBackupSetupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.shield_outlined,
        color: ColorPalette.purple,
        size: 32,
      ),
      title: const Text('Automatic Copy Chalu Karein?'),
      content: const Text(
        'Roz raat 2 baje phone charge aur WiFi par aapka poora hisaab '
        'iCloud / Google Drive par save ho jayega.\n\n'
        'Ye bahut zaroori hai — data safe rahega.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Baad Mein'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Haan, Chalu Karein'),
        ),
      ],
    );
  }
}
