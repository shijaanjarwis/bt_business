import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';

/// Counts up to [value] with a smooth easing animation.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.isCurrency = true,
  });

  final double value;
  final TextStyle? style;
  final Duration duration;
  final bool isCurrency;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final display = isCurrency
            ? CurrencyFormatter.format(animatedValue)
            : animatedValue.toStringAsFixed(0);
        return Text(display, style: style);
      },
    );
  }
}
