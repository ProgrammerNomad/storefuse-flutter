import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/models/product.dart';
import '../../core/deep_links.dart';
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
import '../account/wishlist_ids_provider.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session_provider.dart';
import '../bootstrap/app_ui_config.dart';
import '../bootstrap/bootstrap_provider.dart';
import '../../core/widgets/product_card.dart';
import '../cart/cart_provider.dart';
import 'catalog_repository.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Future<JsonMap> _productFuture;
  Future<({List<JsonMap> reviews, JsonMap? ratingStats})>? _reviewsFuture;
  var _quantity = 1;
  final _selectedOptions = <String, String>{};

  @override
  void initState() {
    super.initState();
    _productFuture = ref
        .read(catalogRepositoryProvider)
        .productBySlug(widget.slug);
  }

  int? _matchVariationId(Product product) {
    return matchProductVariationId(
      variations: product.variations,
      productAttributes: product.attributes,
      selectedOptions: _selectedOptions,
    );
  }

  List<Widget> _reviewTiles(List<JsonMap> reviews) {
    return reviews.map((r) {
      final rating = parseInt(r['rating'], fallback: 0);
      final verified = r['is_verified'] == true;
      return ListTile(
        title: Row(
          children: [
            Expanded(child: Text(r['author']?.toString() ?? 'Customer')),
            if (rating > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          r['content']?.toString() ?? r['review']?.toString() ?? '',
        ),
        trailing: verified
            ? const Chip(
                label: Text('Verified'),
                visualDensity: VisualDensity.compact,
              )
            : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final reviewsEnabled = modules['reviews'] == true;
    final features =
        asJsonMap(
          ref.watch(bootstrapProvider).valueOrNull?.statusData?['features'],
        ) ??
        {};
    final pdpUi = ref.watch(appUiConfigProvider).productScreen;
    final cardConfig = ref.watch(appUiConfigProvider).productCard;

    return AppScaffold(
      title: 'Product',
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share product',
          onPressed: () async {
            final data = await _productFuture;
            final slug = data['slug']?.toString();
            if (slug == null || slug.isEmpty || !mounted) return;
            final env = ref.read(appEnvProvider);
            final text = StoreDeepLinks.productShareText(
              scheme: env.deepLinkScheme,
              slug: slug,
              webPermalink: data['permalink']?.toString(),
            );
            await SharePlus.instance.share(ShareParams(text: text));
          },
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
                _productFuture = ref
                    .read(catalogRepositoryProvider)
                    .productBySlug(widget.slug);
              }),
            );
          }
          final product = Product.fromJson(snapshot.data!);
          if (reviewsEnabled && _reviewsFuture == null) {
            _reviewsFuture = ref
                .read(catalogRepositoryProvider)
                .reviewsData(product.id);
          }
          final variationId = product.isVariable
              ? _matchVariationId(product)
              : null;
          final variation = product.variations
              .where((v) => parseInt(v['id']) == variationId)
              .firstOrNull;
          final selectedProduct = variation == null
              ? product.toJson()
              : {...product.toJson(), ...variation};
          final selectedImage = asJsonMap(variation?['image']);
          final images =
              selectedImage != null && imageUrl(selectedImage) != null
              ? [selectedImage]
              : product.images;
          final canAdd =
              productInStock(selectedProduct) &&
              product.purchasable &&
              (variation?['purchasable'] != false) &&
              {'simple', 'variable'}.contains(product.type) &&
              modules['cart'] != false &&
              (!product.isVariable || variationId != null);
          final rawProduct = snapshot.data!;
          final sku = rawProduct['sku']?.toString();
          final related = asJsonList(rawProduct['related_products']);
          final relatedLimit = pdpUi.relatedCount;
          final visibleRelated = relatedLimit > 0
              ? related.take(relatedLimit).toList()
              : <JsonMap>[];

          Future<void> addToCart() async {
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
              if (!context.mounted) return;
              SnackBarHelper.showException(context, e);
            }
          }

          final addButton = LoadingButton(
            label: 'Add to cart',
            loading: ref.watch(cartProvider).loading,
            onPressed: !canAdd ? null : addToCart,
          );

          final scrollContent = <Widget>[
              if (images.isNotEmpty)
                ProductGallery(key: ValueKey(variationId), images: images),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (pdpUi.showSku && sku != null && sku.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'SKU: $sku',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
              if (productOnSale(selectedProduct))
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SaleBadge(),
                ),
              Row(
                children: [
                  PriceText(price: asJsonMap(selectedProduct['price'])),
                  if (productOnSale(selectedProduct)) ...[
                    const SizedBox(width: 8),
                    Text(
                      priceFormatted(asJsonMap(selectedProduct['regular_price'])),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              StockBadge(product: selectedProduct),
              if (features['pincode_serviceability'] == true)
                _DeliveryPincodeCheck(),
              if (!product.inStock && features['stock_alerts'] == true)
                _BackInStockNotify(slug: widget.slug),
              if (product.isVariable) ...[
                const SizedBox(height: 16),
                ...product.attributes.where((a) => a['variation'] != false).map(
                  (attr) {
                    final name = attr['name']?.toString() ?? 'Option';
                    final optionValues = asJsonList(attr['option_values']);
                    final rawOptions = attr['options'];
                    final options = optionValues.isNotEmpty
                        ? optionValues
                              .map((o) => o['value'].toString())
                              .toList()
                        : rawOptions is List
                        ? rawOptions.map((o) => o.toString()).toList()
                        : <String>[];
                    String optionLabel(String value) =>
                        optionValues
                            .where((o) => o['value'] == value)
                            .firstOrNull?['label']
                            ?.toString() ??
                        value;
                    if (options.isEmpty) return const SizedBox.shrink();
                    final selectable = options
                        .where(
                          (o) => variationOptionIsAvailable(
                            variations: product.variations,
                            productAttributes: product.attributes,
                            attributeName: name,
                            optionValue: o,
                            selectedOptions: _selectedOptions,
                          ),
                        )
                        .toList();
                    final current = _selectedOptions[name];
                    if (current != null &&
                        current.isNotEmpty &&
                        !selectable.contains(current)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() => _selectedOptions.remove(name));
                      });
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String>(
                        initialValue: current?.isNotEmpty == true &&
                                selectable.contains(current)
                            ? current
                            : null,
                        decoration: InputDecoration(labelText: name),
                        items: selectable
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Text(optionLabel(o)),
                              ),
                            )
                            .toList(),
                        onChanged: product.inStock && selectable.isNotEmpty
                            ? (v) => setState(() {
                                if (v != null) {
                                  _selectedOptions[name] = v;
                                } else {
                                  _selectedOptions.remove(name);
                                }
                              })
                            : null,
                      ),
                    );
                  },
                ),
                if (product.isVariable &&
                    variationId == null &&
                    product.inStock)
                  Text(
                    'Select all options',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                StoreHtml(html: product.description!),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  if (modules['wishlist'] == true)
                    IconButton(
                      icon: Icon(
                        ref
                                    .watch(wishlistIdsProvider)
                                    .valueOrNull
                                    ?.contains(product.id) ==
                                true
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      onPressed: () async {
                        if (!ref.read(isLoggedInProvider)) {
                          if (context.mounted) context.push('/auth/login');
                          return;
                        }
                        try {
                          final inList =
                              ref
                                  .read(wishlistIdsProvider)
                                  .valueOrNull
                                  ?.contains(product.id) ==
                              true;
                          if (inList) {
                            await ref
                                .read(wishlistIdsProvider.notifier)
                                .remove(product.id);
                          } else {
                            await ref
                                .read(wishlistIdsProvider.notifier)
                                .add(product.id);
                          }
                          if (context.mounted) {
                            if (!context.mounted) return;
                            SnackBarHelper.showMessage(
                              context,
                              inList
                                  ? 'Removed from wishlist'
                                  : 'Added to wishlist',
                            );
                          }
                        } on StoreFuseApiException catch (e) {
                          if (!context.mounted) return;
                          SnackBarHelper.showException(context, e);
                        }
                      },
                    ),
                ],
              ),
              if (!pdpUi.stickyAddToCart) addButton,
              if (visibleRelated.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Related products',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleRelated.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => SizedBox(
                      width: 160,
                      child: ProductCard(
                        product: visibleRelated[i],
                        cardConfig: cardConfig,
                      ),
                    ),
                  ),
                ),
              ],
              if (reviewsEnabled) ...[
                const SizedBox(height: 32),
                Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
                FutureBuilder<({List<JsonMap> reviews, JsonMap? ratingStats})>(
                  future: _reviewsFuture,
                  builder: (context, revSnap) {
                    if (revSnap.hasError) {
                      return ErrorView(
                        message: 'Could not load reviews.',
                        onRetry: () => setState(() {
                          _reviewsFuture = ref
                              .read(catalogRepositoryProvider)
                              .reviewsData(product.id);
                        }),
                      );
                    }
                    if (!revSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      );
                    }
                    final bundle = revSnap.data!;
                    final reviews = bundle.reviews;
                    final avg =
                        bundle.ratingStats?['average'] ??
                        bundle.ratingStats?['average_rating'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (avg != null) Text('Average rating: $avg'),
                        if (reviews.isEmpty)
                          const Text('No reviews yet.')
                        else
                          ..._reviewTiles(reviews),
                      ],
                    );
                  },
                ),
                if (ref.watch(isLoggedInProvider))
                  _ReviewForm(productId: product.id),
              ],
          ];

          if (!pdpUi.stickyAddToCart) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: scrollContent,
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: scrollContent,
                ),
              ),
              Material(
                elevation: 4,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: addButton,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeliveryPincodeCheck extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeliveryPincodeCheck> createState() =>
      _DeliveryPincodeCheckState();
}

class _DeliveryPincodeCheckState extends ConsumerState<_DeliveryPincodeCheck> {
  final _controller = TextEditingController();
  String? _message;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final pin = _controller.text.trim();
    if (pin.isEmpty) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final client = await ref.read(apiClientProvider.future);
      final data = (await client.lookupPincode(pin)).data;
      final serviceable =
          data['serviceable'] == true || data['is_serviceable'] == true;
      setState(() {
        _message = serviceable
            ? 'Delivery available to $pin'
            : 'Delivery may not be available to $pin';
      });
    } on StoreFuseApiException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Check delivery', style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Pincode / postal code',
                  ),
                  keyboardType: TextInputType.text,
                  onSubmitted: (_) => _check(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _check,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check'),
              ),
            ],
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!),
            ),
        ],
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
            Text(
              'Notify me when back in stock',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Signups are saved on your store. Email delivery requires a '
              'back-in-stock integration (see Bridge extensions docs).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
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
                          if (!context.mounted) return;
                          SnackBarHelper.showMessage(
                            context,
                            result['message']?.toString() ??
                                'Signup recorded.',
                          );
                        }
                      } on StoreFuseApiException catch (e) {
                        if (!context.mounted) return;
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
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              ),
            ),
          ),
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Your review'),
            maxLines: 3,
            validator: (v) =>
                (v == null || v.trim().length < 3) ? 'Min 3 characters' : null,
          ),
          FilledButton(
            onPressed: _submitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _submitting = true);
                    try {
                      await ref
                          .read(authRepositoryProvider)
                          .submitReview(
                            productId: widget.productId,
                            rating: _rating,
                            review: _controller.text,
                          );
                      if (context.mounted) {
                        if (!context.mounted) return;
                        SnackBarHelper.showMessage(context, 'Review submitted');
                      }
                    } on StoreFuseApiException catch (e) {
                      if (!context.mounted) return;
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
