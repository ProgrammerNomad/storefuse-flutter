import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';
import '../../core/ui/show_store_error.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_button.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/product_gallery.dart';
import '../../core/widgets/sale_badge.dart';
import '../../core/widgets/stock_badge.dart';
import '../../core/widgets/store_html.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session_provider.dart';
import '../bootstrap/bootstrap_provider.dart';
import '../cart/cart_provider.dart';
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
  var _quantity = 1;
  final _selectedOptions = <String, String>{};

  @override
  void initState() {
    super.initState();
    _productFuture = ref.read(catalogRepositoryProvider).productBySlug(widget.slug);
  }

  int? _matchVariationId(Product product) {
    if (!product.isVariable || product.variations.isEmpty) return null;
    for (final v in product.variations) {
      final attrs = asJsonList(v['attributes']);
      var match = true;
      for (final a in attrs) {
        final name = a['name']?.toString() ?? a['slug']?.toString() ?? '';
        final option = a['option']?.toString() ?? '';
        if (_selectedOptions[name] != option) {
          match = false;
          break;
        }
      }
      if (match) return parseInt(v['id']);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final reviewsEnabled = modules['reviews'] == true;

    return AppScaffold(
      title: 'Product',
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () => Share.share('Check out ${widget.slug}'),
        ),
      ],
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
          final product = Product.fromJson(snapshot.data!);
          if (reviewsEnabled && _reviewsFuture == null) {
            _reviewsFuture = ref.read(catalogRepositoryProvider).reviews(product.id);
          }
          final variationId = product.isVariable ? _matchVariationId(product) : null;
          final canAdd = product.inStock &&
              (!product.isVariable || variationId != null);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (product.images.isNotEmpty) ProductGallery(images: product.images),
              const SizedBox(height: 12),
              Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
              if (product.price != null && product.price!['sale'] != null)
                const Padding(padding: EdgeInsets.only(top: 4), child: SaleBadge()),
              PriceText(price: product.price),
              const SizedBox(height: 8),
              StockBadge(product: product.toJson()),
              if (!product.inStock && modules['products'] == true)
                _BackInStockNotify(slug: widget.slug),
              if (product.isVariable) ...[
                const SizedBox(height: 16),
                ...product.attributes.map((attr) {
                  final name = attr['name']?.toString() ?? 'Option';
                  final rawOptions = attr['options'];
                  final options = rawOptions is List
                      ? rawOptions.map((o) => o.toString()).where((o) => o.isNotEmpty).toList()
                      : const <String>[];
                  if (options.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DropdownButtonFormField<String>(
                      value: _selectedOptions[name]?.isNotEmpty == true
                          ? _selectedOptions[name]
                          : null,
                      decoration: InputDecoration(labelText: name),
                      items: options
                          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                          .toList(),
                      onChanged: product.inStock
                          ? (v) => setState(() {
                                if (v != null) _selectedOptions[name] = v;
                              })
                          : null,
                    ),
                  );
                }),
                if (product.isVariable && variationId == null && product.inStock)
                  Text(
                    'Select all options',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
              ],
              if (product.description != null && product.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                StoreHtml(html: product.description!),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_quantity', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  if (modules['wishlist'] == true && ref.watch(isLoggedInProvider))
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () async {
                        try {
                          await ref.read(authRepositoryProvider).wishlistAdd(product.id);
                          if (context.mounted) {
                            SnackBarHelper.showMessage(context, 'Added to wishlist');
                          }
                        } on StoreFuseApiException catch (e) {
                          SnackBarHelper.showException(context, e);
                        }
                      },
                    ),
                ],
              ),
              LoadingButton(
                label: 'Add to cart',
                loading: ref.watch(cartProvider).loading,
                onPressed: !canAdd
                    ? null
                    : () async {
                        try {
                          await ref.read(cartProvider.notifier).addProduct(
                                productId: product.id,
                                quantity: _quantity,
                                variationId: variationId,
                              );
                          if (context.mounted) {
                            SnackBarHelper.showMessage(context, 'Added to cart');
                          }
                        } on StoreFuseApiException catch (e) {
                          SnackBarHelper.showException(context, e);
                        }
                      },
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
                if (ref.watch(isLoggedInProvider)) _ReviewForm(productId: product.id),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BackInStockNotify extends ConsumerStatefulWidget {
  const _BackInStockNotify({required this.slug});

  final String slug;

  @override
  ConsumerState<_BackInStockNotify> createState() => _BackInStockNotifyState();
}

class _BackInStockNotifyState extends ConsumerState<_BackInStockNotify> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _consent = false;
  var _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Notify me when back in stock', style: Theme.of(context).textTheme.titleSmall),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Email required';
                if (!t.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: const Text('I agree to receive back-in-stock emails'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            FilledButton.tonal(
              onPressed: !_consent || _submitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _submitting = true);
                      try {
                        final client = await ref.read(apiClientProvider.future);
                        final result = (await client.productNotifySignup(
                          slug: widget.slug,
                          email: _email.text.trim(),
                          consent: _consent,
                        )).data;
                        if (context.mounted) {
                          SnackBarHelper.showMessage(
                            context,
                            result['message']?.toString() ?? 'You will be notified.',
                          );
                        }
                      } on StoreFuseApiException catch (e) {
                        SnackBarHelper.showException(context, e);
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              child: const Text('Notify me'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.productId});

  final int productId;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _formKey = GlobalKey<FormState>();
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            value: _rating,
            decoration: const InputDecoration(labelText: 'Rating'),
            items: List.generate(
              5,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} stars')),
            ),
            onChanged: (v) => setState(() => _rating = v ?? 5),
          ),
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Your review'),
            maxLines: 3,
            validator: (v) => (v == null || v.trim().length < 3) ? 'Min 3 characters' : null,
          ),
          FilledButton(
            onPressed: _submitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _submitting = true);
                    try {
                      await ref.read(authRepositoryProvider).submitReview(
                            productId: widget.productId,
                            rating: _rating,
                            review: _controller.text,
                          );
                      if (context.mounted) {
                        SnackBarHelper.showMessage(context, 'Review submitted');
                      }
                    } on StoreFuseApiException catch (e) {
                      SnackBarHelper.showException(context, e);
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
            child: const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}
