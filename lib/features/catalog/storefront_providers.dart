// Storefront Riverpod providers - do not duplicate provider names elsewhere.
// Storefront Riverpod providers - single source of truth (do not duplicate names elsewhere).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../bootstrap/bootstrap_provider.dart';
import 'catalog_repository.dart';

final homepageProvider = FutureProvider<JsonMap>((ref) async {
  if (ref.watch(bootstrapProvider).valueOrNull?.modules['settings'] == false) {
    return {};
  }
  final client = await ref.watch(apiClientProvider.future);
  return (await client.getHomepage()).data;
});

final navigationProvider = FutureProvider<JsonMap>((ref) async {
  if (ref.watch(bootstrapProvider).valueOrNull?.modules['settings'] == false) {
    return {};
  }
  final client = await ref.watch(apiClientProvider.future);
  return (await client.getNavigation()).data;
});

final countriesProvider = FutureProvider<List<JsonMap>>((ref) async {
  final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
  if (modules['utils'] != true) return const [];
  final client = await ref.read(apiClientProvider.future);
  return asJsonList((await client.getCountries()).data['countries']);
});

final homepageBestSellersProvider = FutureProvider<List<JsonMap>>((ref) async {
  if (ref.watch(bootstrapProvider).valueOrNull?.modules['products'] == false) {
    return [];
  }
  final homepage = await ref.watch(homepageProvider.future);
  final section = asJsonMap(homepage['best_sellers']) ?? {};
  final count = parseInt(section['count'], fallback: 8);
  if (count <= 0) return [];

  final source = section['source']?.toString() ?? 'best-selling';
  final client = await ref.read(apiClientProvider.future);
  final ids = (section['ids'] as List? ?? [])
      .map((id) => parseInt(id))
      .where((id) => id > 0)
      .toList();
  if (source == 'manual' && ids.isEmpty) return [];
  final result = await client.getProducts(
    page: 1,
    perPage: count,
    featured: source == 'featured' ? true : null,
    include: source == 'manual' ? ids : null,
    orderby: source.contains('best') || source == 'popularity'
        ? 'popularity'
        : 'date',
  );
  return listItemsFromPageData(result.data);
});

/// Merchandising blocks from GET /homepage (announcement, hero, trust, promo).
final homepageMerchandisingProvider = Provider<HomepageMerchandising>((ref) {
  final homepage = ref.watch(homepageProvider).valueOrNull ?? {};
  return HomepageMerchandising(
    announcement: asJsonMap(homepage['announcement_bar']),
    hero: asJsonMap(homepage['hero']) ?? {},
    trustItems: asJsonList(homepage['trust_items']),
    promo: asJsonMap(homepage['promo_banner']),
    bestSellersHeading:
        asJsonMap(homepage['best_sellers'])?['heading']?.toString() ??
        'Best Sellers',
    newArrivalsHeading:
        asJsonMap(homepage['new_arrivals'])?['heading']?.toString() ??
        'New Arrivals',
  );
});

class HomepageMerchandising {
  const HomepageMerchandising({
    required this.hero,
    required this.trustItems,
    this.announcement,
    this.promo,
    this.bestSellersHeading = 'Best Sellers',
    this.newArrivalsHeading = 'New Arrivals',
  });

  final JsonMap? announcement;
  final JsonMap hero;
  final List<JsonMap> trustItems;
  final JsonMap? promo;
  final String bestSellersHeading;
  final String newArrivalsHeading;
}

/// Default billing/shipping country from checkout config (no hardcoded locale).
final checkoutDefaultCountryProvider = FutureProvider<String>((ref) async {
  if (ref.watch(bootstrapProvider).valueOrNull?.modules['checkout'] == false) {
    return '';
  }
  try {
    final client = await ref.read(apiClientProvider.future);
    final config = (await client.getCheckoutConfig()).data;
    final country = config['default_country']?.toString().trim() ?? '';
    return country;
  } catch (_) {
    return '';
  }
});

final homepageNewArrivalsProvider = FutureProvider<List<JsonMap>>((ref) async {
  if (ref.watch(bootstrapProvider).valueOrNull?.modules['products'] == false) {
    return [];
  }
  final homepage = await ref.watch(homepageProvider.future);
  final section = asJsonMap(homepage['new_arrivals']) ?? {};
  final count = parseInt(section['count'], fallback: 8);
  if (count <= 0) return [];
  final category = section['category']?.toString();
  final slug = (category != null && category.isNotEmpty) ? category : null;
  return ref
      .read(catalogRepositoryProvider)
      .products(page: 1, perPage: count, category: slug, orderby: 'date');
});
