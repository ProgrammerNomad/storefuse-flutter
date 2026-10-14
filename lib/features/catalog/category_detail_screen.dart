import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/product_card.dart';
import 'catalog_repository.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  JsonMap? _category;
  final _products = <JsonMap>[];
  var _page = 1;
  var _totalPages = 1;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      if (reset) {
        final client = await ref.read(apiClientProvider.future);
        final cat = (await client.getCategory(widget.slug)).data;
        _category = cat;
      }
      final result = await ref
          .read(catalogRepositoryProvider)
          .productsPage(
            page: reset ? 1 : _page + 1,
            category: widget.slug,
            perPage: 24,
          );
      setState(() {
        if (reset) {
          _products
            ..clear()
            ..addAll(result.items);
        } else {
          _products.addAll(result.items);
        }
        _page = result.meta.page;
        _totalPages = result.meta.totalPages <= 0 ? 1 : result.meta.totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _category?['name'] as String? ?? widget.slug;
    final count = _category?['count'];
    return AppScaffold(
      title: title,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(
              message: _error.toString(),
              onRetry: () => _load(reset: true),
            )
          : RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: CustomScrollView(
                slivers: [
                  if (count != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('$count products'),
                      ),
                    ),
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate((_, i) {
                      if (i >= _products.length) return null;
                      return ProductCard(product: _products[i]);
                    }, childCount: _products.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                  ),
                  if (_page < _totalPages)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _loadingMore
                            ? const Center(child: CircularProgressIndicator())
                            : TextButton(
                                onPressed: () => _load(reset: false),
                                child: const Text('Load more'),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
