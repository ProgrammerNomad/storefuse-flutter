import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/price_text.dart';
import 'catalog_repository.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.categorySlug});

  final String? categorySlug;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late Future<List<JsonMap>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(catalogRepositoryProvider).products(
          category: widget.categorySlug,
        );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.categorySlug == null ? 'Products' : 'Category',
      body: FutureBuilder<List<JsonMap>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(_load),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No products yet.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = items[index];
              final slug = p['slug'] as String? ?? '';
              final inStock = productInStock(p);
              return ListTile(
                leading: _thumb(p),
                title: Text(p['name']?.toString() ?? slug),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceText(price: asJsonMap(p['price'])),
                    Text(inStock ? 'In stock' : 'Out of stock',
                        style: TextStyle(
                          color: inStock ? Colors.green : Colors.red,
                          fontSize: 12,
                        )),
                  ],
                ),
                onTap: slug.isEmpty ? null : () => context.push('/products/$slug'),
              );
            },
          );
        },
      ),
    );
  }

  Widget? _thumb(JsonMap p) {
    final images = p['images'];
    if (images is List && images.isNotEmpty) {
      final url = imageUrl(asJsonMap(images.first));
      if (url != null) {
        return Image.network(url, width: 56, height: 56, fit: BoxFit.cover);
      }
    }
    return const Icon(Icons.image_outlined);
  }
}
