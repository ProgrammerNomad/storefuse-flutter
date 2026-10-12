import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/storefuse_client.dart' show StoreFuseApiClient;
import '../../core/models/json_helpers.dart';
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
    final client = await _client();
    final data = (await client.getProducts(
      page: page,
      perPage: perPage,
      category: category,
      orderby: orderby,
    )).data;
    return asJsonList(data['items']);
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
    final client = await _client();
    return asJsonList((await client.search(q: q)).data['items']);
  }

  Future<List<JsonMap>> reviews(int productId) async {
    final client = await _client();
    return asJsonList((await client.getReviews(productId: productId)).data['items']);
  }

  Future<List<JsonMap>> posts({int page = 1}) async {
    final client = await _client();
    return asJsonList((await client.getPosts(page: page)).data['items']);
  }

  Future<JsonMap> notifyBackInStock({required String slug, required String email}) async {
    final client = await _client();
    return (await client.productNotifySignup(slug: slug, email: email)).data;
  }
}
