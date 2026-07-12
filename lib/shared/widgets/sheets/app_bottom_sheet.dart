import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/color_palette.dart';
import '../layout/main_shell_insets.dart';

/// Shows a BT Business bottom sheet with consistent sizing and safe insets.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color backgroundColor = ColorPalette.cardSurface,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: false,
    backgroundColor: backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: builder,
  );
}

/// Universal bottom sheet body — scrollable content with optional sticky footer.
class AppBottomSheetLayout extends StatelessWidget {
  const AppBottomSheetLayout({
    super.key,
    required this.body,
    this.footer,
    this.showHandle = true,
    this.accountForMainNav = true,
    this.horizontalPadding = AppSpacing.lg,
  });

  final Widget body;
  final Widget? footer;
  final bool showHandle;
  final bool accountForMainNav;
  final double horizontalPadding;

  /// Bottom inset so Save/Done stays above nav bar, FAB stack, and home indicator.
  static double footerBottomInset(
    BuildContext context, {
    bool accountForMainNav = true,
  }) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard > 0) return 12;

    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    if (accountForMainNav) {
      return MainShellInsets.navBarHeight + safeBottom + 12;
    }
    return safeBottom + 12;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomInset = footerBottomInset(
      context,
      accountForMainNav: accountForMainNav,
    );
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHandle) ...[
                  const Center(child: _SheetHandle()),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: body,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: footer!,
                  ),
                ] else
                  SizedBox(height: bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Picker-style sheet with a fixed header and scrollable list region.
class AppBottomSheetPickerLayout extends StatelessWidget {
  const AppBottomSheetPickerLayout({
    super.key,
    required this.header,
    required this.child,
    this.footer,
    this.accountForMainNav = true,
    this.initialChildSize = 0.78,
    this.minChildSize = 0.45,
    this.maxChildSize = 0.92,
  });

  final Widget header;
  final Widget child;
  final Widget? footer;
  final bool accountForMainNav;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomInset = AppBottomSheetLayout.footerBottomInset(
      context,
      accountForMainNav: accountForMainNav,
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _SheetHandle()),
                  const SizedBox(height: AppSpacing.lg),
                  header,
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: child),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: footer!,
                    ),
                  ] else
                    SizedBox(height: bottomInset),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: ColorPalette.border,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
