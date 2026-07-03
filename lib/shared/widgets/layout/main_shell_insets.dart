import 'package:flutter/material.dart';

/// Bottom spacing when content sits above [MainShell] navigation.
abstract final class MainShellInsets {
  static const double navBarContentHeight = 62;
  static const double navBarHeight = navBarContentHeight;

  static const double fabDiameter = 56;
  static const double fabGapAboveNav = 24;
  static const double fabStackSpacing = 14;

  static double globalFabStackHeight() {
    return fabDiameter * 2 + fabStackSpacing;
  }

  static const double fabEndMargin = 16;

  static double bottomNavHeight(BuildContext context) {
    return navBarContentHeight + MediaQuery.paddingOf(context).bottom;
  }

  /// Scroll content padding — keeps last fields above bottom nav.
  static double scrollBottom(BuildContext context) {
    return bottomNavHeight(context) + 16;
  }

  /// Scroll padding — clears global FAB stack above bottom nav.
  static double scrollBottomWithFab(BuildContext context) {
    return scrollBottom(context) + globalFabStackHeight() + fabGapAboveNav + 8;
  }

  /// SnackBar margin when global FAB stack is visible.
  static double fabSnackBarBottom(BuildContext context) {
    return bottomNavHeight(context) + fabGapAboveNav + globalFabStackHeight() + 12;
  }

  /// Sticky footer padding — sits above nav or keyboard, never overlaps either.
  static double stickyFooterBottom(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard > 0) return keyboard + 12;
    return navBarHeight + MediaQuery.paddingOf(context).bottom;
  }
}
