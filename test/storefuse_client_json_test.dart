import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/config/env.dart';
import 'package:storefuse_app/core/api/storefuse_client.dart';
import 'package:storefuse_app/core/cache/memory_cache.dart';
import 'package:storefuse_app/core/session/nonce_store.dart';

class FakeTransport implements HttpClientAdapter {
  FakeTransport(this.reply);
  final ResponseBody Function(RequestOptions) reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      reply(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  test('GET tolerates PHP noise before JSON envelope', () async {
    const envelope = {
      'schema': 'storefuse.status.v1',
      'api_version': '1.1.0',
      'data': {'status': 'ok', 'version': '1.1.0'},
    };
    final dio = Dio()
      ..httpClientAdapter = FakeTransport(
        (_) => ResponseBody.fromString(
          '\n\nNotice: foo\n${jsonEncode(envelope)}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
    final client = StoreFuseApiClient(
      env: AppEnv.fromDartDefines(),
      nonces: NonceStore(),
      cache: MemoryCache(),
      dio: dio,
    );
    final status = await client.getStatus();
    expect(status.data['status'], 'ok');
  });
}
