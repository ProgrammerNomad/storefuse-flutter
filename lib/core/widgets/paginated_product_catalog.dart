import 'package:flutter/material.dart';

import '../../features/bootstrap/app_ui_config.dart';
import '../models/json_helpers.dart';
import '../models/paginated_result.dart';
import 'empty_state_view.dart';
import 'error_view.dart';
import 'product_card.dart';
import 'product_list_tile.dart';

typedef PaginatedPageLoader =
    Future<PaginatedResult<JsonMap>> Function(int page);

class PaginatedProductCatalog extends StatefulWidget {
  const PaginatedProductCatalog({
    super.key,
    required this.loadPage,
    required this.catalogConfig,
    required this.cardConfig,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.padding,
    this.physics,
    this.refreshKey,
  });

  final PaginatedPageLoader loadPage;
  final CatalogListUiConfig catalogConfig;
  final ProductCardUiConfig cardConfig;
  final String emptyTitle;
  final String? emptyMessage;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final Object? refreshKey;

  @override
  State<PaginatedProductCatalog> createState() =>
      PaginatedProductCatalogState();
}

class PaginatedProductCatalogState extends State<PaginatedProductCatalog> {
  final _scrollController = ScrollController();
  final _items = <JsonMap>[];
  var _page = 1;
  var _totalPages = 1;
  var _initialLoading = true;
  var _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    refresh();
  }

  @override
  void didUpdateWidget(PaginatedProductCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.catalogConfig.layout != widget.catalogConfig.layout ||
        oldWidget.catalogConfig.columns != widget.catalogConfig.columns) {
      refresh();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> refresh() => _loadFirstPage();

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _initialLoading) {
      return;
    }
    if (_page >= _totalPages) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _error = null;
      _items.clear();
      _page = 1;
    });
    try {
      final result = await widget.loadPage(1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _totalPages = result.meta.totalPages <= 0 ? 1 : result.meta.totalPages;
        _page = result.meta.page;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_page >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final result = await widget.loadPage(next);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _totalPages = result.meta.totalPages <= 0
            ? _page
            : result.meta.totalPages;
        _page = next;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Widget _productTile(JsonMap product) {
    if (widget.catalogConfig.layout == CatalogLayout.list) {
      return ProductListTile(product: product);
    }
    return ProductCard(
      product: product,
      cardConfig: widget.cardConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error.toString(), onRetry: _loadFirstPage);
    }
    if (_items.isEmpty) {
      return EmptyStateView(
        title: widget.emptyTitle,
        message: widget.emptyMessage,
      );
    }

    final physics = widget.physics ?? const AlwaysScrollableScrollPhysics();

    if (widget.catalogConfig.layout == CatalogLayout.grid) {
      final columns = widget.catalogConfig.columns;
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: CustomScrollView(
          controller: _scrollController,
          physics: physics,
          slivers: [
            SliverPadding(
              padding: widget.padding ?? const EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _productTile(_items[i]),
                  childCount: _items.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: widget.catalogConfig.childAspectRatioFor(
                    columns,
                  ),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
              ),
            ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
    }

    final itemCount = _items.length + (_loadingMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: physics,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _productTile(_items[index]);
        },
      ),
    );
  }
}
