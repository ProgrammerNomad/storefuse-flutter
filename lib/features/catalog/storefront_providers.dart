// Storefront Riverpod providers - do not duplicate provider names elsewhere.
// Storefront Riverpod providers - single source of truth (do not duplicate names elsewhere).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../bootstrap/bootstrap_provider.dart';
import 'catalog_repository.dart';

final homepageProvider = FutureProvider<JsonMap>((ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return (await client.getHomepage()).data;
});

final navigationProvider = FutureProvider<JsonMap>((ref) async {
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
  final homepage = await ref.watch(homepageProvider.future);
  final section = asJsonMap(homepage['best_sellers']) ?? {};
  final count = parseInt(section['count'], fallback: 8);
  if (count <= 0) return [];

  final source = section['source']?.toString() ?? 'best-selling';
  final orderby =
      source.contains('best') || source == 'popularity' ? 'popularity' : 'date';
  return ref.read(catalogRepositoryProvider).products(
        page: 1,
        perPage: count,
        orderby: orderby,
      );
});

final homepageNewArrivalsProvider = FutureProvider<List<JsonMap>>((ref) async {
  final homepage = await ref.watch(homepageProvider.future);
  final section = asJsonMap(homepage['new_arrivals']) ?? {};
  final count = parseInt(section['count'], fallback: 8);
  if (count <= 0) return [];
  final category = section['category']?.toString();
  final slug = (category != null && category.isNotEmpty) ? category : null;
  return ref.read(catalogRepositoryProvider).products(
        page: 1,
        perPage: count,
        category: slug,
        orderby: 'date',
      );
});
