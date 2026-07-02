import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_register_fab.dart';
import '../../../../shared/widgets/chips/app_filter_chip.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../providers/party_ledger_extras_provider.dart';
import '../providers/party_providers.dart';
import '../widgets/party_list_tile.dart';
import '../widgets/party_search_bar.dart';

/// Hisaab list — kitna lena hai, kitna dena hai, ek nazar mein.
class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(partySearchQueryProvider.notifier).state = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partyListProvider);
    final filter = ref.watch(partyBalanceFilterProvider);
    final lastActivityMap = ref.watch(partyLastActivityProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Party',
        hindi: 'Hisaab',
      ),
      floatingActionButton: AppRegisterFab(
        onPressed: () => context.push(RouteNames.ledgerPartyNew),
        english: 'New Party',
        hindi: 'Naya Party',
        icon: Icons.person_add,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: PartySearchBar(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(partySearchQueryProvider.notifier).state = value;
                },
                onClear: _clearSearch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip(
                      label: 'Sab',
                      selected: filter == PartyBalanceFilter.all,
                      onSelected: () => ref
                          .read(partyBalanceFilterProvider.notifier)
                          .state = PartyBalanceFilter.all,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Lena Hai',
                      selected: filter == PartyBalanceFilter.lena,
                      onSelected: () => ref
                          .read(partyBalanceFilterProvider.notifier)
                          .state = PartyBalanceFilter.lena,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Dena Hai',
                      selected: filter == PartyBalanceFilter.dena,
                      onSelected: () => ref
                          .read(partyBalanceFilterProvider.notifier)
                          .state = PartyBalanceFilter.dena,
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: 'Saaf Hisaab',
                      selected: filter == PartyBalanceFilter.saaf,
                      onSelected: () => ref
                          .read(partyBalanceFilterProvider.notifier)
                          .state = PartyBalanceFilter.saaf,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: partiesAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Hisaab load nahi ho paya',
                  message: UserErrorMessages.from(error),
                  actionEnglish: 'Try Again', actionHindi: 'Phir Try Karein',
                  onAction: () => ref.invalidate(partyListProvider),
                  icon: Icons.cloud_off_rounded,
                ),
                data: (parties) {
                  if (parties.isEmpty) {
                    return RefreshIndicator(
                      color: ColorPalette.purple,
                      onRefresh: () async {
                        ref.invalidate(partyListProvider);
                        ref.invalidate(partyLastActivityProvider);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                          Center(
                            child: Text(
                              _emptyMessage(filter),
                              style: const TextStyle(
                                fontSize: 16,
                                color: ColorPalette.labelSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const DeveloperFooter(),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async {
                      ref.invalidate(partyListProvider);
                      ref.invalidate(partyLastActivityProvider);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: parties.length + 1,
                      separatorBuilder: (context, index) {
                        if (index >= parties.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index == parties.length) {
                          return const DeveloperFooter();
                        }
                        final party = parties[index];
                        return PartyListTile(
                          party: party,
                          lastActivity: lastActivityMap[party.id],
                          onTap: () => context.push(
                            RouteNames.ledgerPartyDetailPath(party.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage(PartyBalanceFilter filter) {
    return switch (filter) {
      PartyBalanceFilter.lena => 'Abhi kisi se lena nahi',
      PartyBalanceFilter.dena => 'Abhi kisi ko dena nahi',
      PartyBalanceFilter.saaf => 'Saaf hisaab wala koi party nahi',
      PartyBalanceFilter.all => 'Pehla party jodein',
    };
  }
}
