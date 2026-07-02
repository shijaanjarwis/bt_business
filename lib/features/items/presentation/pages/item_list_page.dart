import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/buttons/app_register_fab.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../providers/item_providers.dart';
import '../widgets/item_list_tile.dart';

/// Maal list — naam + unit shortcuts for faster bikri/kharid.
class ItemListPage extends ConsumerStatefulWidget {
  const ItemListPage({super.key});

  @override
  ConsumerState<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends ConsumerState<ItemListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(itemSearchQueryProvider);
    final itemsAsync = ref.watch(itemSearchProvider(query));

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: const AppRegisterAppBar(
        english: 'Goods',
        hindi: 'Maal',
      ),
      floatingActionButton: AppRegisterFab(
        onPressed: () => context.push(RouteNames.stockNew),
        english: 'Add Item',
        hindi: 'Maal Jodein',
        icon: Icons.add_rounded,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AppSearchField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(itemSearchQueryProvider.notifier).state = value;
                },
                onClear: () {
                  _searchController.clear();
                  ref.read(itemSearchQueryProvider.notifier).state = '';
                },
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Maal load nahi ho paya',
                  message: UserErrorMessages.from(error),
                  actionEnglish: 'Try Again', actionHindi: 'Phir Try Karein',
                  onAction: () => ref.invalidate(itemSearchProvider(query)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return RefreshIndicator(
                      color: ColorPalette.purple,
                      onRefresh: () async => ref.invalidate(itemSearchProvider(query)),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
                          Center(
                            child: Text(
                              query.trim().isEmpty
                                  ? 'Pehla maal jodein — bikri/kharid tez hogi'
                                  : 'Match nahi mila — naam ya unit check karein',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                          ),
                          const DeveloperFooter(),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ColorPalette.purple,
                    onRefresh: () async => ref.invalidate(itemSearchProvider(query)),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: items.length + 1,
                      separatorBuilder: (context, index) {
                        if (index >= items.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return const DeveloperFooter();
                        }
                        final item = items[index];
                        return ItemListTile(
                          item: item,
                          onTap: () => context.push(RouteNames.stockEditPath(item.id)),
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
