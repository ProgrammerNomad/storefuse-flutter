import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/routing/store_href.dart';
import '../../core/theme/store_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_loading.dart' show ProductRowSkeleton;
import '../bootstrap/bootstrap_provider.dart';
import '../bootstrap/store_branding.dart';
import 'storefront_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(storeNameProvider);
    final tagline = ref.watch(storeTaglineProvider);
    final showDevInfo = ref.watch(showDevStoreInfoProvider);
    final homepageAsync = ref.watch(homepageProvider);

    return AppScaffold(
      title: name,

      body: homepageAsync.when(
        loading: () => const ProductRowSkeleton(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(homepageProvider),
        ),
        data: (homepage) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homepageProvider);
            ref.invalidate(homepageBestSellersProvider);
            ref.invalidate(homepageNewArrivalsProvider);
            await ref.read(bootstrapProvider.notifier).refresh();
            await ref.read(homepageProvider.future);
          },
          child: _HomepageBody(
            homepage: homepage,
            name: name,
            tagline: tagline,
            showDevInfo: showDevInfo,
          ),
        ),
      ),
    );
  }
}

class _HomepageBody extends ConsumerWidget {
  const _HomepageBody({
    required this.homepage,
    required this.name,
    required this.tagline,
    required this.showDevInfo,
  });

  final JsonMap homepage;
  final String name;
  final String? tagline;
  final bool showDevInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merch = ref.watch(homepageMerchandisingProvider);
    final announcement = merch.announcement;
    final hero = merch.hero;
    final featured = asJsonList(homepage['featured_categories']);
    final promo = merch.promo;
    final bestHeading = merch.bestSellersHeading;
    final newHeading = merch.newArrivalsHeading;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        if (announcement?['enabled'] == true &&
            (announcement?['text']?.toString().isNotEmpty ?? false))
          Material(
            color: parseStoreSeedColor(announcement?['bg_color']?.toString()),
            child: InkWell(
              onTap: announcement?['link']?.toString().isNotEmpty == true
                  ? () => _openHref(context, announcement?['link']?.toString())
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  announcement!['text'].toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hero['badge_text']?.toString().isNotEmpty == true)
                Chip(label: Text(hero['badge_text'].toString())),
              if (hero['headline'] != null)
                Text(
                  hero['headline'].toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                )
              else
                Text(
                  'Welcome to $name',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              if (hero['headline_highlight']?.toString().isNotEmpty == true)
                Text(
                  hero['headline_highlight'].toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (hero['subheadline']?.toString().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(hero['subheadline'].toString()),
                ),
              if (tagline != null) ...[
                const SizedBox(height: 8),
                Text(tagline!),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => _openHref(
                      context,
                      hero['cta_primary_href']?.toString(),
                    ),
                    child: Text(
                      hero['cta_primary_label']?.toString() ?? 'Shop products',
                    ),
                  ),
                  if (hero['cta_secondary_label']?.toString().isNotEmpty ??
                      false)
                    OutlinedButton(
                      onPressed: () => _openHref(
                        context,
                        hero['cta_secondary_href']?.toString(),
                      ),
                      child: Text(hero['cta_secondary_label'].toString()),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_heroImageUrl(hero) != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: _heroImageUrl(hero)!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        if (featured.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final cat = featured[i];
                final slug = cat['slug']?.toString();
                return InkWell(
                  onTap: slug == null
                      ? null
                      : () => context.push('/categories/$slug'),
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: cat['image_url'] != null
                                ? CachedNetworkImage(
                                    imageUrl: cat['image_url'].toString(),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : ColoredBox(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.category),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['label']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (promo?['enabled'] == true) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: parseStoreSeedColor(
                promo?['bg_color']?.toString(),
                fallback: const Color(0xFF1e293b),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (promo?['headline'] != null)
                      Text(
                        promo!['headline'].toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    if (promo?['body'] != null)
                      Text(
                        promo!['body'].toString(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (asJsonMap(promo?['cta'])?['label'] != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _openHref(
                          context,
                          asJsonMap(promo?['cta'])?['href']?.toString(),
                        ),
                        child: Text(
                          asJsonMap(promo?['cta'])!['label'].toString(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        for (final field in ['rating_text', 'shipping_text'])
          if (hero[field]?.toString().isNotEmpty == true)
            ListTile(
              leading: Icon(
                field == 'rating_text'
                    ? Icons.star_outline
                    : Icons.local_shipping_outlined,
              ),
              title: Text(hero[field].toString()),
            ),
        for (final item in merch.trustItems)
          if (item['enabled'] != false)
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: Text(item['title']?.toString() ?? ''),
              subtitle: Text(item['description']?.toString() ?? ''),
            ),
        _ProductRow(title: bestHeading, provider: homepageBestSellersProvider),
        _ProductRow(title: newHeading, provider: homepageNewArrivalsProvider),
        _EmptyCatalogHint(
          bestProvider: homepageBestSellersProvider,
          newProvider: homepageNewArrivalsProvider,
        ),
        if (showDevInfo) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                final bootstrap = ref.watch(bootstrapProvider).valueOrNull;
                if (bootstrap?.statusData == null) {
                  return Text(
                    'Dev flavor - Bridge debug hidden when APP_FLAVOR=prod.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return Text(
                  'Bridge ${bootstrap!.statusData!['version']} · '
                  'Checkout: ${bootstrap.headlessCheckout ? 'headless' : 'redirect'}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String? _heroImageUrl(JsonMap hero) {
    final image = asJsonMap(hero['image']);
    return imageUrl(image) ?? image?['url']?.toString();
  }

  void _openHref(BuildContext context, String? href) {
    final path = href != null ? storeHrefToRoute(href) : null;
    if (path != null) {
      if (path == '/home') {
        context.go(path);
      } else {
        context.push(path);
      }
    } else {
      context.push('/products');
    }
  }
}

class _EmptyCatalogHint extends ConsumerWidget {
  const _EmptyCatalogHint({
    required this.bestProvider,
    required this.newProvider,
  });

  final FutureProvider<List<JsonMap>> bestProvider;
  final FutureProvider<List<JsonMap>> newProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = ref.watch(bestProvider).valueOrNull;
    final newest = ref.watch(newProvider).valueOrNull;
    if (best == null || newest == null) return const SizedBox.shrink();
    if (best.isNotEmpty || newest.isNotEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No products are visible yet. Seed the store with '
            'storefuse-bridge/scripts/local-fixtures.php or add catalog items in WooCommerce.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.title, required this.provider});

  final String title;
  final FutureProvider<List<JsonMap>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(provider);
    return productsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => ListTile(
        title: Text('Unable to load $title'),
        trailing: IconButton(
          tooltip: 'Retry',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(provider),
        ),
      ),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 220 + 80 * MediaQuery.textScalerOf(context).scale(1),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 160,
                  child: ProductCard(product: products[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
