import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../../domain/entities/party.dart';
import '../providers/party_providers.dart';
import '../widgets/party_list_tile.dart';
import '../widgets/party_search_bar.dart';

/// Hisaab list — every party in one notebook.
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
  }

  List<Party> _filterParties(List<Party> parties, PartyBalanceFilter filter) {
    return switch (filter) {
      PartyBalanceFilter.all => parties,
      PartyBalanceFilter.lena =>
        parties.where((party) => party.isReceivable).toList(),
      PartyBalanceFilter.dena =>
        parties.where((party) => party.isPayable).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partyListProvider);
    final filter = ref.watch(partyBalanceFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BilingualLabel(
          english: 'Hisaab',
          hindi: 'Kaun kitna baaki — sab yahan',
          compact: true,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.ledgerPartyNew),
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New Name'),
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
                  setState(() {});
                },
                onClear: _clearSearch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _BalanceFilterRow(filter: filter),
            ),
            Expanded(
              child: partiesAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Hisaab load nahi ho paya',
                  message: error.toString(),
                  actionLabel: 'Try Again',
                  onAction: () => ref.invalidate(partyListProvider),
                  icon: Icons.cloud_off_rounded,
                ),
                data: (parties) {
                  final filtered = _filterParties(parties, filter);

                  if (parties.isEmpty) {
                    return const Center(
                      child: BilingualLabel(
                        english: 'No names yet',
                        hindi: 'Pehla party jodein',
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: BilingualLabel(
                        english: switch (filter) {
                          PartyBalanceFilter.lena => 'Nobody to collect from',
                          PartyBalanceFilter.dena => 'Nobody to pay',
                          PartyBalanceFilter.all => 'No names yet',
                        },
                        hindi: switch (filter) {
                          PartyBalanceFilter.lena => 'Abhi kisi se lena nahi',
                          PartyBalanceFilter.dena => 'Abhi kisi ko dena nahi',
                          PartyBalanceFilter.all => 'Pehla party jodein',
                        },
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async => ref.invalidate(partyListProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final party = filtered[index];
                        return PartyListTile(
                          party: party,
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
}

class _BalanceFilterRow extends ConsumerWidget {
  const _BalanceFilterRow({required this.filter});

  final PartyBalanceFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
          label: 'Sab',
          selected: filter == PartyBalanceFilter.all,
          onSelected: () => ref.read(partyBalanceFilterProvider.notifier).state =
              PartyBalanceFilter.all,
        ),
        _FilterChip(
          label: 'Lena Hai',
          selected: filter == PartyBalanceFilter.lena,
          onSelected: () => ref.read(partyBalanceFilterProvider.notifier).state =
              PartyBalanceFilter.lena,
        ),
        _FilterChip(
          label: 'Dena Hai',
          selected: filter == PartyBalanceFilter.dena,
          onSelected: () => ref.read(partyBalanceFilterProvider.notifier).state =
              PartyBalanceFilter.dena,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? ColorPalette.purple : const Color(0xFF636366),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? ColorPalette.purple : const Color(0xFFE5E5EA),
      ),
    );
  }
}
