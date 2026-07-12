import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';

/// Premium animated microphone — pulse, glow, and voice wave bars.
class VoiceAnimatedMic extends StatelessWidget {
  const VoiceAnimatedMic({
    super.key,
    required this.pulse,
    required this.glow,
    required this.isActive,
    required this.soundLevel,
    required this.showWave,
  });

  final Animation<double> pulse;
  final Animation<double> glow;
  final bool isActive;
  final double soundLevel;
  final bool showWave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulse, glow]),
        builder: (context, child) {
          final pulseScale = isActive ? 0.92 + (pulse.value * 0.12) : 1.0;
          final glowOpacity = isActive ? 0.18 + (glow.value * 0.22) : 0.08;
          final glowScale = isActive ? 1.05 + (glow.value * 0.18) : 1.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: glowScale,
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorPalette.purple.withValues(alpha: glowOpacity),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: ColorPalette.purple.withValues(alpha: 0.28),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? ColorPalette.purple : ColorPalette.purple.withValues(alpha: 0.15),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: ColorPalette.purple.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 52,
                    color: isActive ? Colors.white : ColorPalette.purple,
                  ),
                ),
              ),
              if (showWave)
                Positioned(
                  bottom: 18,
                  child: _VoiceWaveBars(level: soundLevel),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VoiceWaveBars extends StatelessWidget {
  const _VoiceWaveBars({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final phase = (index - 2).abs() * 0.15;
        final height = 8 + (24 * level * (1 - phase)).clamp(0.0, 24.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 5,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Status line under the microphone — stable height, high contrast.
class VoiceStatusLine extends StatelessWidget {
  const VoiceStatusLine({
    super.key,
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return SizedBox(
      height: 52,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: text.hindi.copyWith(
            fontSize: 16,
            height: 1.35,
            color: isError ? ColorPalette.destructive : AppColors.textHindi,
          ),
        ),
      ),
    );
  }
}
