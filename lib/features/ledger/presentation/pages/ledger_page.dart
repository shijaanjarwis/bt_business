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

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partyListProvider);

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
                  if (parties.isEmpty) {
                    return const Center(
                      child: BilingualLabel(
                        english: 'No names yet',
                        hindi: 'Pehla party jodein',
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
