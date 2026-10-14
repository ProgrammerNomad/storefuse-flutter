import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/storefuse_client.dart' show StoreFuseApiClient;
import '../../core/models/json_helpers.dart';
import '../../core/models/paginated_result.dart';
import '../../core/providers/providers.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref);
});

class CatalogRepository {
  CatalogRepository(this.ref);

  final Ref ref;

  Future<StoreFuseApiClient> _client() => ref.read(apiClientProvider.future);

  Future<List<JsonMap>> products({
    int page = 1,
    int perPage = 20,
    String? category,
    String? orderby,
  }) async {
    final pageResult = await productsPage(
      page: page,
      perPage: perPage,
      category: category,
      orderby: orderby,
    );
    return pageResult.items;
  }

  Future<PaginatedResult<JsonMap>> productsPage({
    int page = 1,
    int perPage = 20,
    String? category,
    String? orderby,
    String? order,
    num? minPrice,
    num? maxPrice,
    bool? onSale,
    bool? featured,
  }) async {
    final client = await _client();
    final data = (await client.getProducts(
      page: page,
      perPage: perPage,
      category: category,
      orderby: orderby,
      order: order,
      minPrice: minPrice,
      maxPrice: maxPrice,
      onSale: onSale,
      featured: featured,
    )).data;
    return PaginatedResult.jsonMaps(data);
  }

  Future<JsonMap> productBySlug(String slug) async {
    final client = await _client();
    return (await client.getProduct(slug)).data;
  }

  Future<List<JsonMap>> categories() async {
    final client = await _client();
    return asJsonList((await client.getCategories()).data['items']);
  }

  Future<JsonMap> categoryBySlug(String slug) async {
    final client = await _client();
    return (await client.getCategory(slug)).data;
  }

  Future<List<JsonMap>> searchProducts(String q) async {
    return (await searchPage(q: q)).items;
  }

  Future<PaginatedResult<JsonMap>> searchPage({
    required String q,
    int page = 1,
    int perPage = 20,
  }) async {
    final client = await _client();
    final data = (await client.search(q: q, page: page, perPage: perPage)).data;
    return PaginatedResult.jsonMaps(data);
  }

  Future<List<JsonMap>> reviews(int productId) async {
    return (await reviewsData(productId)).reviews;
  }

  Future<({List<JsonMap> reviews, JsonMap? ratingStats})> reviewsData(
    int productId,
  ) async {
    final client = await _client();
    final data = (await client.getReviews(productId: productId)).data;
    return (
      reviews: listItemsFromPageData(data),
      ratingStats: asJsonMap(data['rating_stats']),
    );
  }

  Future<List<JsonMap>> posts({int page = 1}) async {
    return (await postsPage(page: page)).items;
  }

  Future<PaginatedResult<JsonMap>> postsPage({int page = 1}) async {
    final client = await _client();
    final data = (await client.getPosts(page: page)).data;
    return PaginatedResult.jsonMaps(data);
  }

  Future<JsonMap> notifyBackInStock({
    required String slug,
    required String email,
  }) async {
    final client = await _client();
    return (await client.productNotifySignup(slug: slug, email: email)).data;
  }
}
