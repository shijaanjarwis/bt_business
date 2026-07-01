import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
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
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Maal',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.stockNew),
        backgroundColor: ColorPalette.purple,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Maal Add Karein'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(itemSearchQueryProvider.notifier).state = value;
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Naam ya unit se khojo…',
                  prefixIcon: const Icon(Icons.search_rounded, color: ColorPalette.purple),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(itemSearchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.mic_none_rounded, size: 22),
                        onPressed: () {},
                        tooltip: 'Awaz se khojo (jald)',
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                loading: () => const AppLoadingView(),
                error: (error, _) => AppErrorView(
                  title: 'Maal load nahi ho paya',
                  message: error.toString(),
                  actionLabel: 'Phir try karein',
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
                                color: Color(0xFF636366),
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
