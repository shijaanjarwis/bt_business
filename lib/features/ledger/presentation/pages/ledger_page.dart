import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/labels/bilingual_label.dart';
import '../providers/party_providers.dart';
import '../widgets/party_list_tile.dart';
import '../widgets/party_search_bar.dart';

/// Customer and supplier ledger list with search and filters.
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

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partyListProvider);
    final statusFilter = ref.watch(partyStatusFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BilingualLabel(
          english: 'Ledger',
          hindi: 'Customer aur Supplier ka hisaab',
          compact: true,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.ledgerPartyNew),
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Party'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StatusFilterRow(
                value: statusFilter,
                onChanged: (value) {
                  ref.read(partyStatusFilterProvider.notifier).state = value;
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: partiesAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Ledger load nahi ho paya',
                  message: error.toString(),
                  actionLabel: 'Try Again',
                  onAction: () => ref.invalidate(partyListProvider),
                  icon: Icons.cloud_off_rounded,
                ),
                data: (parties) {
                  if (parties.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const BilingualLabel(
                              english: 'No parties yet',
                              hindi: 'Pehla customer ya supplier add karein',
                            ),
                          ],
                        ),
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
                      itemCount: parties.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final party = parties[index];
                        return PartyListTile(
                          party: party,
                          onTap: () => context.push(
                            RouteNames.ledgerPartyEditPath(party.id),
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

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusChip(
            label: 'All · Sab',
            selected: value == null,
            onSelected: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Active · Chalu',
            selected: value == true,
            onSelected: () => onChanged(true),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Inactive · Band',
            selected: value == false,
            onSelected: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: ColorPalette.purple.withValues(alpha: 0.15),
      checkmarkColor: ColorPalette.purple,
      labelStyle: TextStyle(
        color: selected ? ColorPalette.purple : const Color(0xFF636366),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
