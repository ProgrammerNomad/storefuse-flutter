import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/price_text.dart';
import '../auth/auth_session_provider.dart';
import '../bootstrap/bootstrap_provider.dart';
import '../cart/cart_provider.dart';
import '../auth/auth_repository.dart';
import 'catalog_repository.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Future<JsonMap> _productFuture;
  Future<List<JsonMap>>? _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = ref.read(catalogRepositoryProvider).productBySlug(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final reviewsEnabled = modules['reviews'] == true;

    return AppScaffold(
      title: 'Product',
      body: FutureBuilder<JsonMap>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _productFuture =
                    ref.read(catalogRepositoryProvider).productBySlug(widget.slug);
              }),
            );
          }
          final p = snapshot.data!;
          final id = parseInt(p['id']);
          if (reviewsEnabled && _reviewsFuture == null) {
            _reviewsFuture = ref.read(catalogRepositoryProvider).reviews(id);
          }
          final inStock = productInStock(p);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_heroImage(p) != null) _heroImage(p)!,
              const SizedBox(height: 12),
              Text(p['name']?.toString() ?? widget.slug,
                  style: Theme.of(context).textTheme.headlineSmall),
              PriceText(price: asJsonMap(p['price'])),
              const SizedBox(height: 8),
              Text(inStock ? 'In stock' : 'Out of stock'),
              if (p['description'] != null) ...[
                const SizedBox(height: 16),
                Text(p['description'].toString()),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: !inStock
                    ? null
                    : () async {
                        try {
                          await ref.read(cartProvider.notifier).addProduct(
                                productId: id,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          }
                        } on StoreFuseApiException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        }
                      },
                child: const Text('Add to cart'),
              ),
              if (reviewsEnabled) ...[
                const SizedBox(height: 32),
                Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
                FutureBuilder<List<JsonMap>>(
                  future: _reviewsFuture,
                  builder: (context, revSnap) {
                    if (!revSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      );
                    }
                    final reviews = revSnap.data!;
                    if (reviews.isEmpty) {
                      return const Text('No reviews yet.');
                    }
                    return Column(
                      children: reviews
                          .map(
                            (r) => ListTile(
                              title: Text(r['author']?.toString() ?? 'Customer'),
                              subtitle: Text(r['review']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                if (ref.watch(isLoggedInProvider)) _ReviewForm(productId: id),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget? _heroImage(JsonMap p) {
    final images = p['images'];
    if (images is List && images.isNotEmpty) {
      final url = imageUrl(asJsonMap(images.first));
      if (url != null) {
        return AspectRatio(
          aspectRatio: 1,
          child: Image.network(url, fit: BoxFit.cover),
        );
      }
    }
    return null;
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.productId});

  final int productId;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _controller = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<int>(
          value: _rating,
          items: List.generate(
            5,
            (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} stars')),
          ),
          onChanged: (v) => setState(() => _rating = v ?? 5),
        ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(labelText: 'Your review'),
          maxLines: 3,
        ),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  try {
                    await ref.read(authRepositoryProvider).submitReview(
                          productId: widget.productId,
                          rating: _rating,
                          review: _controller.text,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review submitted')),
                      );
                    }
                  } on StoreFuseApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _submitting = false);
                  }
                },
          child: const Text('Submit review'),
        ),
      ],
    );
  }
}
