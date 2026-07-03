import 'package:flutter/material.dart';

import '../layout/main_shell_insets.dart';

/// Positions the global FAB stack above bottom navigation — never overlaps tabs.
class VoiceFabLocation extends FloatingActionButtonLocation {
  const VoiceFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;

    return Offset(
      scaffoldGeometry.scaffoldSize.width -
          fabSize.width -
          MainShellInsets.fabEndMargin -
          scaffoldGeometry.minInsets.right,
      scaffoldGeometry.contentBottom -
          fabSize.height -
          MainShellInsets.fabGapAboveNav,
    );
  }
}
