import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/ledger/presentation/providers/party_providers.dart';
import 'app_bottom_nav.dart';
import 'global_fab_manager.dart';
import 'global_fab_stack.dart';
import 'voice_fab_location.dart';

/// Root scaffold wrapping all primary tabs with bottom navigation.
class MainShell extends ConsumerWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  AppTab get _currentTab => AppTab.values[navigationShell.currentIndex];

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
    final path = GoRouterState.of(context).uri.path;
    final showFabs = GlobalFabManager.shouldShow(path);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentTab: _currentTab,
        onTabSelected: (tab) => _onTabSelected(ref, tab),
      ),
      floatingActionButton: showFabs
          ? GlobalFabStack(
              onPlusPressed: () => GlobalFabManager.onPlusPressed(context, ref),
              onVoicePressed: () => GlobalFabManager.onVoicePressed(context),
            )
          : null,
      floatingActionButtonLocation: const VoiceFabLocation(),
    );
  }
}
