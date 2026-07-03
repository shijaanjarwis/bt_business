import 'package:flutter/material.dart';

import '../../../core/theme/app_text_theme.dart';
import 'app_branding.dart';

/// Subtle developer credit at the bottom of major scrollable screens.
class DeveloperFooter extends StatelessWidget {
  const DeveloperFooter({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Text(
        AppBranding.developerFooter,
        textAlign: TextAlign.center,
        style: context.appText.meta.copyWith(fontWeight: FontWeight.w400),
      ),
    );
  }
}
