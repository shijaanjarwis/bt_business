import 'package:flutter/material.dart';

/// Fade-and-slide entrance animation with staggered delay.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.index,
    required this.child,
    this.delay = 60,
    this.duration = const Duration(milliseconds: 480),
    this.offsetY = 18,
  });

  final int index;
  final Widget child;
  final int delay;
  final Duration duration;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final delayMs = widget.index * widget.delay;
    final totalMs = widget.duration.inMilliseconds + delayMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    final interval = Interval(
      delayMs / totalMs,
      1,
      curve: Curves.easeOutCubic,
    );

    _fade = CurvedAnimation(parent: _controller, curve: interval);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: interval));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
