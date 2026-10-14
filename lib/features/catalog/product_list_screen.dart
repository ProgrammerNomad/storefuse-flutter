import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../core/widgets/product_list_tile.dart';
import 'catalog_repository.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.categorySlug});

  final String? categorySlug;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _listKey = GlobalKey<PaginatedListViewState>();
  String? _orderby;
  String _order = 'desc';
  bool _onSaleOnly = false;
  double? _minPrice;
  double? _maxPrice;

  Future<void> _openFilters() async {
    var orderby = _orderby;
    var order = _order;
    var onSale = _onSaleOnly;
    final minCtrl = TextEditingController(text: _minPrice?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toString() ?? '');

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sort & filter',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: orderby,
                        decoration: const InputDecoration(labelText: 'Sort by'),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Recommended'),
                          ),
                          DropdownMenuItem(
                            value: 'date',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'price',
                            child: Text('Price'),
                          ),
                          DropdownMenuItem(
                            value: 'popularity',
                            child: Text('Popularity'),
                          ),
                          DropdownMenuItem(
                            value: 'rating',
                            child: Text('Rating'),
                          ),
                        ],
                        onChanged: (v) => setModalState(() => orderby = v),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: order,
                        decoration: const InputDecoration(labelText: 'Order'),
                        items: const [
                          DropdownMenuItem(
                            value: 'desc',
                            child: Text('Highest / newest first'),
                          ),
                          DropdownMenuItem(
                            value: 'asc',
                            child: Text('Lowest / oldest first'),
                          ),
                        ],
                        onChanged: (v) =>
                            setModalState(() => order = v ?? 'desc'),
                      ),
                      SwitchListTile(
                        value: onSale,
                        onChanged: (v) => setModalState(() => onSale = v),
                        title: const Text('On sale only'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Min price',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Max price',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    final minText = minCtrl.text.trim();
    final maxText = maxCtrl.text.trim();
    minCtrl.dispose();
    maxCtrl.dispose();
    if (applied != true) return;

    setState(() {
      _orderby = orderby;
      _order = order;
      _onSaleOnly = onSale;
      _minPrice = double.tryParse(minText);
      _maxPrice = double.tryParse(maxText);
    });
    _listKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.categorySlug == null ? 'Products' : 'Category',
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _openFilters,
          tooltip: 'Filter',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => _listKey.currentState?.refresh(),
        child: PaginatedListView(
          key: _listKey,
          physics: const AlwaysScrollableScrollPhysics(),
          emptyTitle: 'No products yet',
          emptyMessage: 'Check back soon for new items.',
          loadPage: (page) => ref
              .read(catalogRepositoryProvider)
              .productsPage(
                page: page,
                category: widget.categorySlug,
                orderby: _orderby,
                order: _order,
                minPrice: _minPrice,
                maxPrice: _maxPrice,
                onSale: _onSaleOnly ? true : null,
              ),
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, p, _) => ProductListTile(product: p),
        ),
      ),
    );
  }
}
