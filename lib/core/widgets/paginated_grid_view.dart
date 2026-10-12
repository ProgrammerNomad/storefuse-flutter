import 'package:flutter/material.dart';

import '../models/json_helpers.dart';
import 'empty_state_view.dart';
import 'error_view.dart';
import 'paginated_list_view.dart';

class PaginatedGridView extends StatefulWidget {
  const PaginatedGridView({
    super.key,
    required this.loadPage,
    required this.itemBuilder,
    required this.gridDelegate,
    this.emptyTitle = 'Nothing here yet',
    this.padding,
    this.refreshKey,
  });

  final PaginatedPageLoader loadPage;
  final Widget Function(BuildContext context, JsonMap item) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final String emptyTitle;
  final EdgeInsetsGeometry? padding;
  final Object? refreshKey;

  @override
  State<PaginatedGridView> createState() => _PaginatedGridViewState();
}

class _PaginatedGridViewState extends State<PaginatedGridView> {
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
    _loadFirstPage();
  }

  @override
  void didUpdateWidget(PaginatedGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _loadFirstPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _initialLoading) return;
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
        _totalPages = result.meta.totalPages <= 0 ? _page : result.meta.totalPages;
        _page = next;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
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
      return EmptyStateView(title: widget.emptyTitle);
    }
    final count = _items.length + (_loadingMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding ?? const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: widget.gridDelegate,
        itemCount: count,
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}
