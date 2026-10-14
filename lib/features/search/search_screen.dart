import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/paginated_product_catalog.dart';
import '../bootstrap/app_ui_config.dart';
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
    final ui = ref.watch(appUiConfigProvider);
    final catalog = ui.catalogForScreen('search');
    final title = ui.screenTitle('search') ?? 'Search';

    return AppScaffold(
      title: title,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: ui.searchScreen.placeholder.isNotEmpty
                    ? ui.searchScreen.placeholder
                    : 'Search products (min 2 chars)',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          if (!canSearch)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (ui.searchScreen.trendingTerms.isNotEmpty) ...[
                    Text(
                      'Trending Searches',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final term in ui.searchScreen.trendingTerms)
                          ActionChip(
                            label: Text(term),
                            onPressed: () {
                              _controller.text = term;
                              setState(() => _query = term);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 32),
                  const EmptyStateView(
                    title: 'Start typing to search',
                    message: 'Enter at least 2 characters.',
                    icon: Icons.search,
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: PaginatedProductCatalog(
                key: ValueKey(_query),
                catalogConfig: catalog,
                cardConfig: ui.productCard,
                emptyTitle: 'No results',
                emptyMessage: 'Try a different search term.',
                loadPage: (page) => ref
                    .read(catalogRepositoryProvider)
                    .searchPage(q: _query, page: page),
              ),
            ),
        ],
      ),
    );
  }
}
