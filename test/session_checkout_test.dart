import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:storefuse_app/config/env.dart';
import 'package:storefuse_app/core/api/storefuse_client.dart';
import 'package:storefuse_app/core/cache/memory_cache.dart';
import 'package:storefuse_app/core/session/nonce_store.dart';
import 'package:storefuse_app/core/session/secure_cookie_storage.dart';

class FakeTransport implements HttpClientAdapter {
  FakeTransport(this.reply);
  final ResponseBody Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => reply(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Map<String, dynamic> data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'authenticated GET refreshes a core WordPress nonce error once',
    () async {
      var reads = 0;
      var bootstraps = 0;
      final nonces = NonceStore()..wpNonce = 'expired';
      final dio = Dio()
        ..httpClientAdapter = FakeTransport((request) {
          if (request.path.endsWith('/admin-ajax.php')) {
            bootstraps++;
            return response({
              'success': true,
              'data': {'nonce': 'fresh', 'cart_nonce': 'wc-fresh'},
            });
          }
          reads++;
          if (reads == 1) {
            expect(request.headers['X-WP-Nonce'], 'expired');
            return response({
              'code': 'rest_cookie_invalid_nonce',
              'message': 'Expired',
            }, 403);
          }
          expect(request.headers['X-WP-Nonce'], 'fresh');
          return response({
            'data': {'logged_in': true, 'id': 12},
          });
        });
      final client = StoreFuseApiClient(
        env: AppEnv.fromDartDefines(),
        nonces: nonces,
        cache: MemoryCache(),
        dio: dio,
      );
      expect((await client.authMe()).data['id'], 12);
      expect(reads, 2);
      expect(bootstraps, 1);
    },
  );
  test(
    'checkout response loss survives a new client and reuses the original key',
    () async {
      final keys = <String>[];
      StoreFuseApiClient makeClient(bool loseResponse) {
        final dio = Dio()
          ..httpClientAdapter = FakeTransport((request) {
            keys.add(request.headers['Idempotency-Key'] as String);
            if (loseResponse) {
              throw DioException(
                requestOptions: request,
                type: DioExceptionType.receiveTimeout,
              );
            }
            return response({
              'data': {'order_id': 42, 'order_key': 'wc_order_test'},
            });
          });
        return StoreFuseApiClient(
          env: AppEnv.fromDartDefines(),
          nonces: NonceStore()..wcNonce = 'cart',
          cache: MemoryCache(),
          dio: dio,
        );
      }

      final original = makeClient(true);
      final body = {
        'billing': {'email': 'test@example.test'},
        'payment_method': 'cod',
      };
      await expectLater(original.checkoutHeadless(body), throwsException);
      final restarted = makeClient(false);
      expect(await restarted.pendingCheckout(), isNotNull);
      await expectLater(
        restarted.checkoutHeadless({'payment_method': 'bacs'}),
        throwsException,
      );
      final result = await restarted.checkoutHeadless(body);
      expect(result.data['order_id'], 42);
      expect(keys.length, 2);
      expect(keys[1], keys[0]);
      expect(await restarted.pendingCheckout(), isNull);
      await restarted.clearSessionCookies();
      expect(await restarted.lastOrderKey(), isNull);
    },
  );
  test('protected storage isolates site and flavor', () async {
    final dev = SecureCookieStorage('dev|https://one.example');
    final prod = SecureCookieStorage('prod|https://one.example');
    final other = SecureCookieStorage('dev|https://two.example');
    await dev.write('cookie', 'secret');
    expect(await dev.read('cookie'), 'secret');
    expect(await prod.read('cookie'), isNull);
    expect(await other.read('cookie'), isNull);
  });
}
