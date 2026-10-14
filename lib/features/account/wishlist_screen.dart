import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/ui/show_store_error.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/cached_thumbnail.dart';
import '../../core/widgets/price_text.dart';
import '../auth/auth_repository.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  late Future<List<JsonMap>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = ref.read(authRepositoryProvider).wishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Wishlist',
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<JsonMap>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [Center(child: Text(snapshot.error.toString()))],
              );
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyStateView(
                    title: 'Wishlist is empty',
                    icon: Icons.favorite_border,
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final product = asJsonMap(item['product']) ?? item;
                final productId = parseInt(product['id'] ?? item['product_id']);
                final slug = product['slug'] as String? ?? '';
                final url = productThumbnailUrl(product);
                return ListTile(
                  leading: cachedThumbnail(url: url, size: 48),
                  title: Text(product['name']?.toString() ?? 'Product'),
                  subtitle: PriceText(price: asJsonMap(product['price'])),
                  onTap: slug.isEmpty
                      ? null
                      : () => context.push('/products/$slug'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .wishlistRemove(productId);
                        _reload();
                      } on StoreFuseApiException catch (e) {
                        if (context.mounted) {
                          if (!context.mounted) return;
                          SnackBarHelper.showException(context, e);
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
