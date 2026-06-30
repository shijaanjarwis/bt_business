import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/home/presentation/widgets/dashboard_voice_button.dart';
import 'app_bottom_nav.dart';

/// Root scaffold wrapping all primary tabs with bottom navigation.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  AppTab get _currentTab => AppTab.values[navigationShell.currentIndex];

  bool get _showVoiceButton => _currentTab == AppTab.home;

  void _onTabSelected(AppTab tab) {
    navigationShell.goBranch(
      tab.index,
      initialLocation: tab.index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentTab: _currentTab,
        onTabSelected: _onTabSelected,
      ),
      floatingActionButton: _showVoiceButton
          ? const DashboardVoiceButton(floating: true)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
