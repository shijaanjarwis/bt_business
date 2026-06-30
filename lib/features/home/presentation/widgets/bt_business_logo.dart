import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

/// BT Business brand header — logo placeholder + app name + subtitle.
class BtBusinessLogo extends StatelessWidget {
  const BtBusinessLogo({super.key});

  static const _logoAssetPath = 'assets/images/bt_business_logo.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LogoPlaceholder(assetPath: _logoAssetPath),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BT Business',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Color(0xFF1C1C1E),
                  height: 1.15,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Bharat Traders - Your Smart Business Partner',
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

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorPalette.purple.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.purple.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorPalette.purpleLight,
                  ColorPalette.purple,
                ],
              ),
            ),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'LOGO',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
