import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

/// Purple floating voice action button for the dashboard.
class DashboardVoiceButton extends StatelessWidget {
  const DashboardVoiceButton({
    super.key,
    this.onPressed,
    this.floating = false,
  });

  final VoidCallback? onPressed;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      elevation: floating ? 6 : 0,
      shadowColor: ColorPalette.purple.withValues(alpha: 0.35),
      color: ColorPalette.purple,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onPressed ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Voice jald aa raha hai'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                ),
              );
            },
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: floating ? 22 : 24,
            vertical: floating ? 16 : 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: floating ? 24 : 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: floating ? 16 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!floating) return button;

    return Transform.translate(
      offset: Offset(0, -math.max(0.0, MediaQuery.paddingOf(context).bottom * 0.15)),
      child: button,
    );
  }
}
