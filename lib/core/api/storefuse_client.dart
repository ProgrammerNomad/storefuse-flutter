import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../session/secure_cookie_storage.dart';

import '../../config/env.dart';
import '../cache/memory_cache.dart';
import '../models/json_helpers.dart';
import '../session/nonce_store.dart';
import 'api_exception.dart';
import 'envelope.dart';

class StoreFuseApiClient {
  StoreFuseApiClient({
    required this.env,
    required this.nonces,
    required this.cache,
    Dio? dio,
    CookieJar? cookieJar,
  }) : _dio = dio ?? Dio(),
       _cookieJar = cookieJar {
    _dio.options.baseUrl = env.apiBaseUrl;
    _dio.options.connectTimeout = env.connectTimeout;
    _dio.options.receiveTimeout = env.receiveTimeout;
    _dio.options.headers['Accept'] = 'application/json';
    if (_cookieJar != null) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
    // Request bodies, cookies, nonces and reset/order keys must never be logged.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.cancelToken ??= _sessionRequests;
          final wp = nonces.wpNonce;
          if (wp != null && wp.isNotEmpty) {
            options.headers['X-WP-Nonce'] = wp;
          }
          if (_isNoStorePath(options.path)) {
            options.headers['Cache-Control'] = 'no-store';
          }
          final token = nonces.cartToken;
          if (token != null && token.isNotEmpty) {
            options.headers['X-StoreFuse-Cart-Token'] = token;
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final body = error.response?.data;
          final code = body is Map
              ? (body['error'] is Map ? body['error']['code'] : body['code'])
              : null;
          final request = error.requestOptions;
          if ({'invalid_nonce', 'rest_cookie_invalid_nonce'}.contains(code) &&
              request.extra['nonceRetried'] != true) {
            try {
              await bootstrapNonces();
              request.extra['nonceRetried'] = true;
              request.headers['X-WP-Nonce'] = nonces.wpNonce;
              if (request.headers.containsKey('X-WC-Nonce')) {
                request.headers['X-WC-Nonce'] = nonces.wcNonce;
              }
              return handler.resolve(await _dio.fetch<dynamic>(request));
            } catch (_) {
              // Surface the original failed request; never retry payment errors.
            }
          }
          handler.next(error);
        },
        onResponse: (response, handler) {
          nonces.updateFromHeaders(response.headers.map);
          response.data = _resolveDevelopmentUrls(response.data);
          final data = response.data;
          if (data is Map<String, dynamic>) {
            final inner = data['data'];
            if (inner is Map<String, dynamic>) {
              nonces.updateFromJson(inner);
            }
          }
          handler.next(response);
        },
      ),
    );
    if (env.enableHttpLogs) {
      if (!kDebugMode) {
        throw StateError('ENABLE_HTTP_LOGS is only supported in debug builds');
      }
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  final AppEnv env;
  final NonceStore nonces;
  final MemoryCache cache;
  final Dio _dio;
  final CookieJar? _cookieJar;
  CancelToken _sessionRequests = CancelToken();
  Future<void>? _refreshSession;

  static Future<StoreFuseApiClient> create(AppEnv env) async {
    final jar = PersistCookieJar(
      storage: SecureCookieStorage('${env.flavor}|${env.bridgeBaseUrl}'),
      deleteHostCookiesWhenLoadFailed: false,
    );
    await jar.forceInit();
    env.validate();
    // Remove only the two known legacy cookie stores inside this app's sandbox.
    final documents = await getApplicationDocumentsDirectory();
    for (final name in ['cookies_dev', 'cookies_prod']) {
      final legacy = Directory('${documents.path}/$name');
      if (await FileSystemEntity.type(legacy.path, followLinks: false) ==
          FileSystemEntityType.directory) {
        final parent = await documents.resolveSymbolicLinks();
        final resolved = await legacy.resolveSymbolicLinks();
        if (resolved.startsWith('$parent${Platform.pathSeparator}')) {
          await legacy.delete(recursive: true);
        }
      }
    }
    return StoreFuseApiClient(
      env: env,
      nonces: NonceStore(),
      cache: MemoryCache(),
      cookieJar: jar,
    );
  }

  dynamic _resolveDevelopmentUrls(dynamic data) {
    if (data is String) return env.resolveStoreUrl(data);
    if (data is List) return data.map(_resolveDevelopmentUrls).toList();
    if (data is Map<String, dynamic>) {
      return data.map(
        (key, value) => MapEntry(key, _resolveDevelopmentUrls(value)),
      );
    }
    return data;
  }

  bool _isNoStorePath(String path) {
    const prefixes = [
      '/cart',
      '/auth',
      '/checkout',
      '/account',
      '/orders',
      '/addresses',
      '/wishlist',
      '/downloads',
    ];
    return prefixes.any((p) => path.startsWith(p));
  }

  Future<JsonMap> _getEnvelope(
    String path, {
    Map<String, dynamic>? query,
    bool useCache = false,
    Duration cacheTtl = const Duration(minutes: 2),
  }) async {
    final cacheKey = useCache ? '$path?$query' : null;
    if (cacheKey != null) {
      final hit = cache.get<JsonMap>(cacheKey);
      if (hit != null) return hit;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final body = response.data;
      if (body == null) {
        throw StoreFuseApiException(message: 'Empty response.');
      }
      if (body.containsKey('error')) {
        throw EnvelopeParser.parseError(body);
      }
      if (cacheKey != null) {
        cache.set(cacheKey, body, ttl: cacheTtl);
      }
      return body;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> clearSessionCookies() async {
    _sessionRequests.cancel('Session ended');
    _sessionRequests = CancelToken();
    await _cookieJar?.deleteAll();
    nonces.clear();
    cache.clear();
    await _sessionStorage.delete('checkout_attempt');
    await _sessionStorage.delete('last_order_key');
  }

  static String generateIdempotencyKey() {
    final random = Random.secure();
    return 'sf-${DateTime.now().millisecondsSinceEpoch}-'
        '${random.nextInt(0x7fffffff).toRadixString(16)}';
  }

  Future<JsonMap> _mutateEnvelope(
    String path, {
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
    bool wcNonce = false,
    bool wpNonce = false,
    Map<String, String>? extraHeaders,
    bool recoverWpNonce = true,
  }) async {
    try {
      return await _mutateEnvelopeOnce(
        path,
        method: method,
        data: data,
        query: query,
        wcNonce: wcNonce,
        wpNonce: wpNonce,
        extraHeaders: extraHeaders,
      );
    } on StoreFuseApiException catch (e) {
      final isNonceError = {
        'missing_wp_nonce',
        'invalid_nonce',
        'rest_cookie_invalid_nonce',
        'missing_wc_nonce',
      }.contains(e.code);
      if (recoverWpNonce && isNonceError) {
        await bootstrapNonces();
        return _mutateEnvelopeOnce(
          path,
          method: method,
          data: data,
          query: query,
          wcNonce: wcNonce,
          wpNonce: wpNonce,
          extraHeaders: extraHeaders,
        );
      }
      rethrow;
    }
  }

  Future<JsonMap> _mutateEnvelopeOnce(
    String path, {
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
    bool wcNonce = false,
    bool wpNonce = false,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, dynamic>{};
    if (wcNonce) {
      final n = nonces.wcNonce;
      if (n == null || n.isEmpty) {
        throw StoreFuseApiException(
          message: 'Cart session expired. Pull to refresh.',
          code: 'missing_wc_nonce',
        );
      }
      headers['X-WC-Nonce'] = n;
    }
    if (wpNonce) {
      final n = nonces.wpNonce;
      if (n == null || n.isEmpty) {
        throw StoreFuseApiException(
          message: 'Session expired. Please sign in again.',
          code: 'missing_wp_nonce',
        );
      }
      headers['X-WP-Nonce'] = n;
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method, headers: headers),
      );
      final body = response.data;
      if (body == null) {
        throw StoreFuseApiException(message: 'Empty response.');
      }
      if (body.containsKey('error')) {
        throw EnvelopeParser.parseError(body);
      }
      return body;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  StoreFuseApiException _mapDioError(DioException e) {
    final connectionFailed =
        e.error is SocketException ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
    if (connectionFailed) {
      final devHint = env.isProd
          ? ''
          : ' Cannot reach store at ${env.bridgeBaseUrl}. '
                'Start XAMPP (Apache) and on Android emulator use http://10.0.2.2.';
      return StoreFuseApiException(
        message: 'You appear to be offline. Check your connection.$devHint',
        isOffline: true,
      );
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      return EnvelopeParser.parseError(data);
    }
    return EnvelopeParser.parseHttpBody(data, e.response?.statusCode);
  }

  Future<EnvelopeResult<JsonMap>> getStatus() async {
    final json = await _getEnvelope('/status');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getSettings() async {
    final json = await _getEnvelope('/settings', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getHomepage() async {
    final json = await _getEnvelope('/homepage', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getNavigation() async {
    final json = await _getEnvelope('/navigation', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getProducts({
    int page = 1,
    int perPage = 20,
    String? category,
    String? tag,
    String? orderby,
    String? order,
    num? minPrice,
    num? maxPrice,
    bool? onSale,
    bool? featured,
    List<int>? include,
  }) async {
    final json = await _getEnvelope(
      '/products',
      query: {
        'page': page,
        'per_page': perPage,
        'category': ?category,
        'tag': ?tag,
        'orderby': ?orderby,
        'order': ?order,
        'min_price': ?minPrice,
        'max_price': ?maxPrice,
        if (onSale == true) 'on_sale': true,
        if (featured == true) 'featured': true,
        if (include != null) 'include': include.join(','),
      },
      useCache: false,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getProduct(String slug) async {
    final json = await _getEnvelope('/products/$slug', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getCategories() async {
    final json = await _getEnvelope('/categories', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getCategory(String slug) async {
    final json = await _getEnvelope('/categories/$slug', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> search({
    required String q,
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _getEnvelope(
      '/search',
      query: {'q': q, 'page': page, 'per_page': perPage},
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getAttributes() async {
    final json = await _getEnvelope('/attributes', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getTags() async {
    final json = await _getEnvelope('/tags', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getPosts({int page = 1}) async {
    final json = await _getEnvelope(
      '/posts',
      query: {'page': page},
      useCache: false,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getPost(String slug) async {
    final json = await _getEnvelope('/posts/$slug', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getReviews({required int productId}) async {
    final json = await _getEnvelope(
      '/reviews',
      query: {'product_id': productId},
      useCache: false,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> submitReview({
    required Map<String, dynamic> body,
  }) async {
    final json = await _mutateEnvelope(
      '/reviews',
      method: 'POST',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getCart() async {
    final json = await _getEnvelope('/cart');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<void> bootstrapNonces() async {
    final pending = _refreshSession;
    if (pending != null) return pending;
    final future = _bootstrapSession();
    _refreshSession = future;
    try {
      await future;
    } finally {
      _refreshSession = null;
    }
  }

  Future<void> _bootstrapSession() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${env.bridgeBaseUrl.replaceAll(RegExp(r'/+$'), '')}/wp-admin/admin-ajax.php',
        data: {'action': 'storefuse_session'},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final body = response.data;
      if (body?['success'] != true || body?['data'] is! Map) {
        throw StoreFuseApiException(
          message: 'Could not restore your store session.',
        );
      }
      nonces.updateFromJson(Map<String, dynamic>.from(body!['data'] as Map));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<Cookie>> cookiesFor(Uri uri) async =>
      await _cookieJar?.loadForRequest(uri) ?? [];

  Future<EnvelopeResult<JsonMap>> cartAdd(Map<String, dynamic> body) async {
    final json = await _mutateEnvelope(
      '/cart/add',
      method: 'POST',
      data: body,
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> cartUpdate(Map<String, dynamic> body) async {
    final json = await _mutateEnvelope(
      '/cart/update',
      method: 'PUT',
      data: body,
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> cartRemove(Map<String, dynamic> body) async {
    final json = await _mutateEnvelope(
      '/cart/remove',
      method: 'DELETE',
      data: body,
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> cartApplyCoupon(String code) async {
    final json = await _mutateEnvelope(
      '/cart/coupon',
      method: 'POST',
      data: {'code': code},
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> cartRemoveCoupon(String code) async {
    final json = await _mutateEnvelope(
      '/cart/coupon',
      method: 'DELETE',
      data: {'code': code},
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> authMe() async {
    final json = await _getEnvelope('/auth/me');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> authLogin(Map<String, dynamic> body) async {
    final json = await _mutateEnvelope(
      '/auth/login',
      method: 'POST',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> authRegister(
    Map<String, dynamic> body,
  ) async {
    final json = await _mutateEnvelope(
      '/auth/register',
      method: 'POST',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> authLogout() async {
    final json = await _mutateEnvelope(
      '/auth/logout',
      method: 'POST',
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> authForgotPassword(String email) async {
    final json = await _mutateEnvelope(
      '/auth/forgot-password',
      method: 'POST',
      data: {'email': email},
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> authResetPassword(
    Map<String, dynamic> body,
  ) async {
    final json = await _mutateEnvelope(
      '/auth/reset-password',
      method: 'POST',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> accountDeletionStatus() async {
    final json = await _getEnvelope('/account/deletion-request');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<String?> lastOrderKey() => _sessionStorage.read('last_order_key');

  Future<EnvelopeResult<JsonMap>> requestAccountDeletion() async {
    final json = await _mutateEnvelope(
      '/account/deletion-request',
      method: 'POST',
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getAccount() async {
    final json = await _getEnvelope('/account');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> updateAccount(
    Map<String, dynamic> body,
  ) async {
    final json = await _mutateEnvelope(
      '/account',
      method: 'PUT',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> changePassword(
    Map<String, dynamic> body,
  ) async {
    final json = await _mutateEnvelope(
      '/account/change-password',
      method: 'POST',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getAddresses() async {
    final json = await _getEnvelope('/addresses');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> updateBilling(
    Map<String, dynamic> body,
  ) async {
    final json = await _mutateEnvelope(
      '/addresses/billing',
      method: 'PUT',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> updateShipping(
    Map<String, dynamic> body,
  ) async {
    final json = await _mutateEnvelope(
      '/addresses/shipping',
      method: 'PUT',
      data: body,
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getWishlist() async {
    final json = await _getEnvelope('/wishlist');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> wishlistAdd(int productId) async {
    final json = await _mutateEnvelope(
      '/wishlist/add',
      method: 'POST',
      data: {'product_id': productId},
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> wishlistRemove(int productId) async {
    final json = await _mutateEnvelope(
      '/wishlist/remove',
      method: 'DELETE',
      data: {'product_id': productId},
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getDownloads() async {
    final json = await _getEnvelope('/downloads');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getCheckoutConfig() async {
    final json = await _getEnvelope('/checkout/config');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getPaymentMethods() async {
    final json = await _getEnvelope('/checkout/payment-methods');
    return EnvelopeParser.parseSuccessDynamic(json, (data) {
      if (data is List) {
        return {'methods': asJsonList(data)};
      }
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{};
    });
  }

  Future<EnvelopeResult<JsonMap>> getShippingMethods({
    Map<String, dynamic>? address,
  }) async {
    final json = await _getEnvelope(
      '/checkout/shipping-methods',
      query: address,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> checkoutRedirectUrl() async {
    final json = await _mutateEnvelope(
      '/checkout/redirect-url',
      method: 'POST',
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  SecureCookieStorage get _sessionStorage =>
      SecureCookieStorage('${env.flavor}|${env.bridgeBaseUrl}');

  Future<JsonMap?> pendingCheckout() async {
    final raw = await _sessionStorage.read('checkout_attempt');
    return raw == null ? null : asJsonMap(jsonDecode(raw));
  }

  Future<EnvelopeResult<JsonMap>> checkoutQuote(JsonMap body) async {
    final json = await _mutateEnvelope(
      '/checkout/quote',
      method: 'POST',
      data: body,
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> checkoutHeadless(
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final previous = await pendingCheckout();
    if (previous != null && jsonEncode(previous['body']) != jsonEncode(body)) {
      throw StoreFuseApiException(
        message:
            'An earlier checkout is unresolved. Restore its details and retry, or check your orders before starting another purchase.',
      );
    }
    final key =
        previous?['key']?.toString() ??
        idempotencyKey ??
        generateIdempotencyKey();
    await _sessionStorage.write(
      'checkout_attempt',
      jsonEncode({'key': key, 'body': body}),
    );
    late final JsonMap json;
    try {
      json = await _mutateEnvelope(
        '/checkout',
        method: 'POST',
        data: body,
        wcNonce: true,
        extraHeaders: {'Idempotency-Key': key},
      );
    } on StoreFuseApiException catch (e) {
      // These failures happen before the server records/creates an order.
      if ({
        'validation_error',
        'invalid_email',
        'out_of_stock',
      }.contains(e.code)) {
        await _sessionStorage.delete('checkout_attempt');
      }
      rethrow;
    }
    final result = EnvelopeParser.parseSuccess(json, (d) => d);
    final orderKey = result.data['order_key']?.toString();
    if (orderKey != null && orderKey.isNotEmpty) {
      await _sessionStorage.write('last_order_key', orderKey);
    }
    final orderId = result.data['order_id'];
    if (orderId != null) {
      await _sessionStorage.write('last_order_id', orderId.toString());
    }
    await _sessionStorage.delete('checkout_attempt');
    return result;
  }

  Future<String?> resolveCheckoutOrderKey(JsonMap checkoutData) async {
    final direct = checkoutData['order_key']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final orderId = parseInt(checkoutData['order_id']);
    if (orderId > 0) {
      try {
        final order = (await getOrderById(orderId)).data;
        final key = order['order_key']?.toString();
        if (key != null && key.isNotEmpty) return key;
      } catch (_) {
        // Fall through to durable local hints.
      }
    }
    final storedKey = await _sessionStorage.read('last_order_key');
    if (storedKey != null && storedKey.isNotEmpty) return storedKey;
    return null;
  }

  Future<EnvelopeResult<JsonMap>> getOrderByKey(String key) async {
    final json = await _getEnvelope('/orders/$key');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getOrders({
    int page = 1,
    int perPage = 10,
  }) async {
    final json = await _getEnvelope(
      '/orders',
      query: {'page': page, 'per_page': perPage},
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getOrderById(int id) async {
    final json = await _getEnvelope('/orders/$id');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> cancelOrder(int id) async {
    final json = await _mutateEnvelope(
      '/orders/$id/cancel',
      method: 'POST',
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> reorder(int id) async {
    final json = await _mutateEnvelope(
      '/orders/$id/reorder',
      method: 'POST',
      wcNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> returnRequest(
    int id, {
    String? reason,
  }) async {
    final json = await _mutateEnvelope(
      '/orders/$id/return-request',
      method: 'POST',
      data: {'reason': ?reason},
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getTracking(int id) async {
    final json = await _getEnvelope('/orders/$id/tracking');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getInvoice(int id) async {
    final json = await _getEnvelope('/orders/$id/invoice');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> getCountries() async {
    final json = await _getEnvelope('/utils/countries', useCache: false);
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> lookupPincode(String pincode) async {
    final json = await _getEnvelope('/utils/pincode/$pincode');
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final json = await _mutateEnvelope(
      '/account/device-token',
      method: 'POST',
      data: {'token': token, 'platform': platform},
      wpNonce: true,
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }

  Future<EnvelopeResult<JsonMap>> productNotifySignup({
    required String slug,
    required String email,
    bool consent = true,
  }) async {
    final json = await _mutateEnvelope(
      '/products/$slug/notify',
      method: 'POST',
      data: {'email': email, 'consent': consent, 'website': ''},
    );
    return EnvelopeParser.parseSuccess(json, (d) => d);
  }
}
