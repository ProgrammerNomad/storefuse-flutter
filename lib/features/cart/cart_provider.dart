import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/storefuse_client.dart' show StoreFuseApiClient;
import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../bootstrap/bootstrap_provider.dart';

class CartState {
  const CartState({this.data, this.loading = false, this.error});

  final JsonMap? data;
  final bool loading;
  final StoreFuseApiException? error;

  int get itemCount => parseInt(data?['item_count']);

  CartState copyWith({
    JsonMap? data,
    bool? loading,
    StoreFuseApiException? error,
  }) {
    return CartState(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    final bootstrap = ref.watch(bootstrapProvider).valueOrNull;
    return CartState(data: bootstrap?.cartData);
  }

  Future<StoreFuseApiClient> _client() async {
    return ref.read(apiClientProvider.future);
  }

  Future<T> _withNonceRecovery<T>(
    Future<T> Function(StoreFuseApiClient client) action,
  ) async {
    try {
      final client = await _client();
      return await action(client);
    } on StoreFuseApiException catch (e) {
      if (e.code != 'missing_wc_nonce') rethrow;
      final client = await _client();
      await client.bootstrapNonces();
      return action(client);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final cart = (await _withNonceRecovery(
        (c) async => (await c.getCart()).data,
      ));
      state = CartState(data: cart);
    } on StoreFuseApiException catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> addProduct({
    required int productId,
    int quantity = 1,
    int? variationId,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final cart = await _withNonceRecovery((client) async {
        if (client.nonces.wcNonce == null) {
          await client.bootstrapNonces();
        }
        final body = <String, dynamic>{
          'product_id': productId,
          'quantity': quantity,
          'variation_id': ?variationId,
        };
        return (await client.cartAdd(body)).data;
      });
      state = CartState(data: cart);
    } on StoreFuseApiException catch (e) {
      state = state.copyWith(loading: false, error: e);
      rethrow;
    }
  }

  Future<void> updateLine({required String key, required int quantity}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final cart = await _withNonceRecovery(
        (client) async => (await client.cartUpdate({
          'cart_item_key': key,
          'key': key,
          'quantity': quantity,
        })).data,
      );
      state = CartState(data: cart);
    } on StoreFuseApiException catch (e) {
      state = state.copyWith(loading: false, error: e);
      rethrow;
    }
  }

  Future<void> removeLine(String key) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final cart = await _withNonceRecovery(
        (client) async =>
            (await client.cartRemove({'cart_item_key': key, 'key': key})).data,
      );
      state = CartState(data: cart);
    } on StoreFuseApiException catch (e) {
      state = state.copyWith(loading: false, error: e);
      rethrow;
    }
  }

  Future<void> applyCoupon(String code) async {
    final client = await _client();
    final cart = (await client.cartApplyCoupon(code)).data;
    state = CartState(data: cart);
  }

  Future<void> removeCoupon(String code) async {
    final client = await _client();
    final cart = (await client.cartRemoveCoupon(code)).data;
    state = CartState(data: cart);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});
