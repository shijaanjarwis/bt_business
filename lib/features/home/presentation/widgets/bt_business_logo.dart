import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/app_branding.dart';

/// BT Business brand header — Bharat Traders logo beside app name.
class BtBusinessLogo extends StatelessWidget {
  const BtBusinessLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _BrandLogo(),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppBranding.appName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: ColorPalette.labelPrimary,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 3),
              Text(
                AppBranding.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.labelSecondary,
                  height: 1.25,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorPalette.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        AppBranding.logoAssetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorPalette.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'BT',
              style: TextStyle(
                color: ColorPalette.purple,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
