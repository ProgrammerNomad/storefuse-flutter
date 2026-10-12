import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/storefuse_client.dart' show StoreFuseApiClient;
import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../cart/cart_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

class AuthRepository {
  AuthRepository(this.ref);

  final Ref ref;

  Future<StoreFuseApiClient> _client() => ref.read(apiClientProvider.future);

  Future<void> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final client = await _client();
    await client.bootstrapNonces();
    await client.authLogin({
      'email': email,
      'password': password,
      'remember': remember,
    });
    await client.authMe();
    await ref.read(cartProvider.notifier).refresh();
  }

  Future<void> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final client = await _client();
    await client.bootstrapNonces();
    await client.authRegister({
      'email': email,
      'password': password,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    });
    await login(email: email, password: password);
  }

  Future<void> logout() async {
    final client = await _client();
    try {
      await client.authLogout();
    } finally {
      client.nonces.wpNonce = null;
      await ref.read(cartProvider.notifier).refresh();
    }
  }

  Future<void> forgotPassword(String email) async {
    final client = await _client();
    await client.bootstrapNonces();
    await client.authForgotPassword(email);
  }

  Future<void> resetPassword({
    required String key,
    required String login,
    required String password,
  }) async {
    final client = await _client();
    await client.bootstrapNonces();
    await client.authResetPassword({
      'key': key,
      'login': login,
      'password': password,
    });
  }

  Future<JsonMap> account() async {
    final client = await _client();
    return (await client.getAccount()).data;
  }

  Future<JsonMap> updateAccount(JsonMap body) async {
    final client = await _client();
    return (await client.updateAccount(body)).data;
  }

  Future<JsonMap> addresses() async {
    final client = await _client();
    return (await client.getAddresses()).data;
  }

  Future<void> updateBilling(JsonMap body) async {
    final client = await _client();
    await client.updateBilling(body);
  }

  Future<void> updateShipping(JsonMap body) async {
    final client = await _client();
    await client.updateShipping(body);
  }

  Future<List<JsonMap>> wishlist() async {
    final client = await _client();
    return asJsonList((await client.getWishlist()).data['items']);
  }

  Future<void> wishlistAdd(int productId) async {
    final client = await _client();
    await client.wishlistAdd(productId);
  }

  Future<void> wishlistRemove(int productId) async {
    final client = await _client();
    await client.wishlistRemove(productId);
  }

  Future<List<JsonMap>> downloads() async {
    final client = await _client();
    return asJsonList((await client.getDownloads()).data['items']);
  }

  Future<void> submitReview({
    required int productId,
    required int rating,
    required String review,
  }) async {
    final client = await _client();
    await client.submitReview(body: {
      'product_id': productId,
      'rating': rating,
      'review': review,
    });
  }

  Future<bool> isLoggedIn() async {
    final client = await _client();
    final me = (await client.authMe()).data;
    return me['logged_in'] == true;
  }
}
