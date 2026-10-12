import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/product_card.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  JsonMap? _category;
  List<JsonMap> _products = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await ref.read(apiClientProvider.future);
      final cat = (await client.getCategory(widget.slug)).data;
      final products =
          (await client.getProducts(category: widget.slug, perPage: 24)).data;
      setState(() {
        _category = cat;
        _products = asJsonList(products['items']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _category?['name'] as String? ?? widget.slug;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error.toString(), onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (_, i) => ProductCard(product: _products[i]),
                  ),
                ),
    );
  }
}
