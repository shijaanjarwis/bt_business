import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/color_palette.dart';
import 'shared/widgets/labels/bilingual_label.dart';

/// Shown when bootstrap fails before the main app can start.
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: ColorPalette.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: ColorPalette.iconPrimary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const BilingualLabel(
                    english: 'App could not start',
                    hindi: 'App start nahi ho paya',
                    compact: true,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.labelSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
