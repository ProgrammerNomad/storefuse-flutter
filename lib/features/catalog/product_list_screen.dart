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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.categorySlug == null ? 'Products' : 'Category',
      body: RefreshIndicator(
        onRefresh: () async => _listKey.currentState?.refresh(),
        child: PaginatedListView(
          key: _listKey,
          physics: const AlwaysScrollableScrollPhysics(),
          emptyTitle: 'No products yet',
          emptyMessage: 'Check back soon for new items.',
          loadPage: (page) => ref.read(catalogRepositoryProvider).productsPage(
                page: page,
                category: widget.categorySlug,
              ),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, p, _) => ProductListTile(product: p),
        ),
      ),
    );
  }
}
