import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../core/widgets/product_list_tile.dart';
import '../catalog/catalog_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _query.length >= 2;

    return AppScaffold(
      title: 'Search',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search products (min 2 chars)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          if (!canSearch)
            const Expanded(
              child: EmptyStateView(
                title: 'Start typing to search',
                message: 'Enter at least 2 characters.',
                icon: Icons.search,
              ),
            )
          else
            Expanded(
              child: PaginatedListView(
                key: ValueKey(_query),
                emptyTitle: 'No results',
                emptyMessage: 'Try a different search term.',
                loadPage: (page) => ref
                    .read(catalogRepositoryProvider)
                    .searchPage(q: _query, page: page),
                itemBuilder: (context, p, _) => ProductListTile(product: p),
              ),
            ),
        ],
      ),
    );
  }
}
