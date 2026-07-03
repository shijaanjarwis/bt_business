import 'package:flutter/material.dart';

/// Tap blank area to dismiss keyboard — applied app-wide on every form.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  static void unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unfocus,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
