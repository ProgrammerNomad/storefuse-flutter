import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/storefuse_client.dart' show StoreFuseApiClient;
import '../../core/models/json_helpers.dart';
import '../../core/models/paginated_result.dart';
import '../../core/providers/providers.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref);
});

class OrdersRepository {
  OrdersRepository(this.ref);

  final Ref ref;

  Future<StoreFuseApiClient> _client() => ref.read(apiClientProvider.future);

  Future<List<JsonMap>> list({int page = 1, int perPage = 10}) async {
    return (await listPage(page: page, perPage: perPage)).items;
  }

  Future<PaginatedResult<JsonMap>> listPage({
    int page = 1,
    int perPage = 10,
  }) async {
    final client = await _client();
    final data = (await client.getOrders(page: page, perPage: perPage)).data;
    return PaginatedResult.jsonMaps(data);
  }

  Future<JsonMap> byId(int id) async {
    final client = await _client();
    return (await client.getOrderById(id)).data;
  }

  Future<JsonMap> byKey(String key) async {
    final client = await _client();
    return (await client.getOrderByKey(key)).data;
  }

  Future<JsonMap> cancel(int id) async {
    final client = await _client();
    return (await client.cancelOrder(id)).data;
  }

  Future<JsonMap> reorder(int id) async {
    try {
      final client = await _client();
      return (await client.reorder(id)).data;
    } on StoreFuseApiException catch (e) {
      if (e.code != 'missing_wc_nonce') rethrow;
      final client = await _client();
      await client.bootstrapNonces();
      return (await client.reorder(id)).data;
    }
  }

  Future<JsonMap> returnRequest(int id, {String? reason}) async {
    final client = await _client();
    return (await client.returnRequest(id, reason: reason)).data;
  }

  Future<JsonMap> tracking(int id) async {
    final client = await _client();
    return (await client.getTracking(id)).data;
  }

  Future<JsonMap> invoice(int id) async {
    final client = await _client();
    return (await client.getInvoice(id)).data;
  }
}
