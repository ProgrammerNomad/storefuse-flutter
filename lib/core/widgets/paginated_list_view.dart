import 'package:flutter/material.dart';

import '../models/json_helpers.dart';
import '../models/paginated_result.dart';
import 'empty_state_view.dart';
import 'error_view.dart';

typedef PaginatedPageLoader = Future<PaginatedResult<JsonMap>> Function(int page);

class PaginatedListView extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.loadPage,
    required this.itemBuilder,
    this.separatorBuilder,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.refreshKey,
  });

  final PaginatedPageLoader loadPage;
  final Widget Function(BuildContext context, JsonMap item, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final String emptyTitle;
  final String? emptyMessage;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Object? refreshKey;

  @override
  State<PaginatedListView> createState() => PaginatedListViewState();
}

class PaginatedListViewState extends State<PaginatedListView> {
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
  void didUpdateWidget(PaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
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
        _totalPages = result.meta.totalPages <= 0 ? _page : result.meta.totalPages;
        _page = next;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
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
      return EmptyStateView(
        title: widget.emptyTitle,
        message: widget.emptyMessage,
      );
    }

    final itemCount = _items.length + (_loadingMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        shrinkWrap: widget.shrinkWrap,
        itemCount: itemCount,
        separatorBuilder: widget.separatorBuilder ?? (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}
