import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps each store and build flavor in its own OS-protected namespace.
class SecureCookieStorage extends Storage {
  SecureCookieStorage(String scope, {FlutterSecureStorage? storage})
    : _prefix = 'storefuse.${base64Url.encode(utf8.encode(scope))}.',
      _storage = storage ?? const FlutterSecureStorage();

  final String _prefix;
  final FlutterSecureStorage _storage;

  String _key(String key) => '$_prefix${base64Url.encode(utf8.encode(key))}';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _storage.read(key: _key(key));

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: _key(key), value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: _key(key));

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}
