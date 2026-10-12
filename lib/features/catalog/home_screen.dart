import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/routing/store_href.dart';
import '../../core/theme/store_colors.dart';
import '../../core/widgets/app_scaffold.dart';
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
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => context.push('/search'),
        ),
      ],
      body: homepageAsync.when(
        loading: () => const ProductRowSkeleton(),
        error: (e, _) => _FallbackHome(name: name, tagline: tagline, showDevInfo: showDevInfo),
        data: (homepage) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homepageProvider);
            ref.invalidate(homepageBestSellersProvider);
            ref.invalidate(homepageNewArrivalsProvider);
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
    final announcement = asJsonMap(homepage['announcement_bar']);
    final hero = asJsonMap(homepage['hero']) ?? {};
    final featured = asJsonList(homepage['featured_categories']);
    final promo = asJsonMap(homepage['promo_banner']);
    final bestHeading =
        asJsonMap(homepage['best_sellers'])?['heading']?.toString() ?? 'Best Sellers';
    final newHeading =
        asJsonMap(homepage['new_arrivals'])?['heading']?.toString() ?? 'New Arrivals';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (announcement?['enabled'] == true &&
            (announcement?['text']?.toString().isNotEmpty ?? false))
          Material(
            color: parseStoreSeedColor(announcement?['bg_color']?.toString()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                announcement!['text'].toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hero['headline'] != null)
                Text(
                  hero['headline'].toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                )
              else
                Text('Welcome to $name', style: Theme.of(context).textTheme.headlineSmall),
              if (tagline != null) ...[
                const SizedBox(height: 8),
                Text(tagline!),
              ] else if (hero['subheadline'] != null) ...[
                const SizedBox(height: 8),
                Text(hero['subheadline'].toString()),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => _openHref(context, hero['cta_primary_href']?.toString()),
                    child: Text(hero['cta_primary_label']?.toString() ?? 'Shop products'),
                  ),
                  if (hero['cta_secondary_label']?.toString().isNotEmpty ?? false)
                    OutlinedButton(
                      onPressed: () => _openHref(context, hero['cta_secondary_href']?.toString()),
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
                child: CachedNetworkImage(imageUrl: _heroImageUrl(hero)!, fit: BoxFit.cover),
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
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final cat = featured[i];
                final slug = cat['slug']?.toString();
                return InkWell(
                  onTap: slug == null ? null : () => context.push('/categories/$slug'),
                  child: SizedBox(
                    width: 100,
                    child: Column(
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
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              color: parseStoreSeedColor(promo?['bg_color']?.toString(), fallback: const Color(0xFF1e293b)),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (promo?['headline'] != null)
                      Text(
                        promo!['headline'].toString(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    if (promo?['body'] != null)
                      Text(promo!['body'].toString(), style: const TextStyle(color: Colors.white70)),
                    if (asJsonMap(promo?['cta'])?['label'] != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            _openHref(context, asJsonMap(promo?['cta'])?['href']?.toString()),
                        child: Text(asJsonMap(promo?['cta'])!['label'].toString()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        _ProductRow(
          title: bestHeading,
          provider: homepageBestSellersProvider,
        ),
        _ProductRow(
          title: newHeading,
          provider: homepageNewArrivalsProvider,
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

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.title, required this.provider});

  final String title;
  final FutureProvider<List<JsonMap>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(provider);
    return productsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(width: 160, child: ProductCard(product: products[i])),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FallbackHome extends StatelessWidget {
  const _FallbackHome({
    required this.name,
    required this.tagline,
    required this.showDevInfo,
  });

  final String name;
  final String? tagline;
  final bool showDevInfo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Welcome to $name', style: Theme.of(context).textTheme.headlineSmall),
        if (tagline != null) ...[
          const SizedBox(height: 8),
          Text(tagline!),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => context.push('/products'),
              child: const Text('Shop products'),
            ),
            OutlinedButton(
              onPressed: () => context.push('/categories'),
              child: const Text('Categories'),
            ),
          ],
        ),
      ],
    );
  }
}
