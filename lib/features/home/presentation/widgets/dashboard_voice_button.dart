import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

/// Purple floating voice action button with subtle pulse animation.
class DashboardVoiceButton extends StatefulWidget {
  const DashboardVoiceButton({
    super.key,
    this.onPressed,
    this.floating = false,
  });

  final VoidCallback? onPressed;
  final bool floating;

  @override
  State<DashboardVoiceButton> createState() => _DashboardVoiceButtonState();
}

class _DashboardVoiceButtonState extends State<DashboardVoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scale;
  bool _pulseStarted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scale = Tween<double>(begin: 1, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pulseStarted && TickerMode.valuesOf(context).enabled) {
      _pulseStarted = true;
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = ScaleTransition(
      scale: _scale,
      child: Material(
        elevation: widget.floating ? 8 : 0,
        shadowColor: ColorPalette.purple.withValues(alpha: 0.45),
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        child: InkWell(
          onTap: widget.onPressed ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Voice module coming soon'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  ),
                );
              },
          borderRadius: BorderRadius.circular(32),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ColorPalette.purpleLight, ColorPalette.purple],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.purple.withValues(alpha: 0.42),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.floating ? 26 : 28,
                vertical: widget.floating ? 16 : 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: widget.floating ? 26 : 22,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    'Voice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.floating ? 17 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.floating) return button;

    return Transform.translate(
      offset: Offset(0, -math.max(0.0, MediaQuery.paddingOf(context).bottom * 0.15)),
      child: button,
    );
  }
}
