import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/home/presentation/widgets/dashboard_voice_button.dart';
import '../../../features/ledger/presentation/providers/party_providers.dart';
import 'app_bottom_nav.dart';

/// Root scaffold wrapping all primary tabs with bottom navigation.
class MainShell extends ConsumerWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  AppTab get _currentTab => AppTab.values[navigationShell.currentIndex];

  bool get _showVoiceButton => _currentTab == AppTab.home;

  void _onTabSelected(WidgetRef ref, AppTab tab) {
    if (tab == AppTab.ledger) {
      ref.read(partyBalanceFilterProvider.notifier).state =
          PartyBalanceFilter.all;
    }
    navigationShell.goBranch(
      tab.index,
      initialLocation: tab.index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentTab: _currentTab,
        onTabSelected: (tab) => _onTabSelected(ref, tab),
      ),
      floatingActionButton: _showVoiceButton
          ? const DashboardVoiceButton(floating: true)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
