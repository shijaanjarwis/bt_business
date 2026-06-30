import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';

enum AppTab { home, ledger, stock, sales, purchases }

/// iOS-style bottom navigation for the five daily shopkeeper workflows.
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
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                selected: currentTab == AppTab.home,
                onTap: () => onTabSelected(AppTab.home),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Hisaab',
                selected: currentTab == AppTab.ledger,
                onTap: () => onTabSelected(AppTab.ledger),
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'Items',
                selected: currentTab == AppTab.stock,
                onTap: () => onTabSelected(AppTab.stock),
              ),
              _NavItem(
                icon: Icons.sell_outlined,
                label: 'Sale',
                selected: currentTab == AppTab.sales,
                onTap: () => onTabSelected(AppTab.sales),
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Purchase',
                selected: currentTab == AppTab.purchases,
                onTap: () => onTabSelected(AppTab.purchases),
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? ColorPalette.purple.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                    letterSpacing: -0.2,
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
