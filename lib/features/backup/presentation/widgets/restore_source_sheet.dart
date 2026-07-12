import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/backup_providers.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';

/// Restore source picker — cloud or .btbackup file.
Future<void> showRestoreSourceSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback onRestoreFromFile,
  required VoidCallback onRestoreFromCloud,
}) {
  final isIos = Platform.isIOS;
  final cloudName = ref.read(cloudBackupPortProvider).providerName;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorPalette.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final text = context.appText;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Wapas kaise laayein?',
                style: text.primaryBold.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Cloud ya .btbackup file se restore karein.',
                style: text.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _RestoreOptionTile(
                text: text,
                icon: Icons.cloud_download_outlined,
                title: 'Restore from Cloud',
                subtitle: isIos ? 'iCloud Drive se' : '$cloudName se',
                onTap: () {
                  Navigator.pop(context);
                  onRestoreFromCloud();
                },
              ),
              const SizedBox(height: 10),
              _RestoreOptionTile(
                text: text,
                icon: Icons.folder_open_outlined,
                title: 'Restore from .btbackup File',
                subtitle: 'Phone se file chuniye',
                onTap: () {
                  Navigator.pop(context);
                  onRestoreFromFile();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RestoreOptionTile extends StatelessWidget {
  const _RestoreOptionTile({
    required this.text,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppTextTheme text;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.cardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorPalette.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: ColorPalette.purple, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.primaryBold.copyWith(fontSize: 16)),
                    Text(subtitle, style: text.secondary.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ColorPalette.iconPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
