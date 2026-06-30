import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';

enum AppTab { home, ledger, stock, reports, ai }

/// iOS-style bottom navigation bar for the main app shell.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.cardSurface.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentTab == AppTab.home,
                onTap: () => onTabSelected(AppTab.home),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Ledger',
                selected: currentTab == AppTab.ledger,
                onTap: () => onTabSelected(AppTab.ledger),
              ),
              const SizedBox(width: 56),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'Stock',
                selected: currentTab == AppTab.stock,
                onTap: () => onTabSelected(AppTab.stock),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                selected: currentTab == AppTab.reports,
                onTap: () => onTabSelected(AppTab.reports),
              ),
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'AI',
                selected: currentTab == AppTab.ai,
                onTap: () => onTabSelected(AppTab.ai),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ColorPalette.purple : ColorPalette.labelSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? ColorPalette.purple.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
