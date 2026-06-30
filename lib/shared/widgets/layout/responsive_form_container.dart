import 'package:flutter/material.dart';

import '../../../core/platform/adaptive_breakpoints.dart';

/// Constrains form content width on larger screens.
class ResponsiveFormContainer extends StatelessWidget {
  const ResponsiveFormContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth =
        width >= AdaptiveBreakpoints.medium ? 560.0 : double.infinity;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
