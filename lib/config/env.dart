/// Runtime configuration via `--dart-define`.
class AppEnv {
  AppEnv._({
    required this.bridgeBaseUrl,
    required this.apiNamespace,
    required this.flavor,
    required this.deepLinkScheme,
    required this.enableHttpLogs,
  });

  static const minSupportedBridgeVersion = '1.1.0';

  final String bridgeBaseUrl;
  final String apiNamespace;
  final String flavor;
  final String deepLinkScheme;
  final bool enableHttpLogs;

  String get apiBaseUrl {
    final base = bridgeBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/wp-json/$apiNamespace';
  }

  bool get isProd => flavor == 'prod';

  /// Shorter timeouts in dev so splash fails fast when XAMPP/emulator URL is wrong.
  Duration get connectTimeout =>
      isProd ? const Duration(seconds: 30) : const Duration(seconds: 10);

  Duration get receiveTimeout =>
      isProd ? const Duration(seconds: 30) : const Duration(seconds: 10);

  /// WordPress site root when [url] accidentally includes `/wp-json/...`.
  static String normalizeBridgeBaseUrl(String url, String apiNamespace) {
    var value = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (value.isEmpty) return value;
    final ns = apiNamespace.replaceAll(RegExp(r'^/+|/+$'), '');
    final suffix = '/wp-json/$ns';
    if (value.length >= suffix.length &&
        value.substring(value.length - suffix.length).toLowerCase() ==
            suffix.toLowerCase()) {
      value = value.substring(0, value.length - suffix.length);
      value = value.replaceAll(RegExp(r'/+$'), '');
    }
    return value;
  }

  static AppEnv fromDartDefines() {
    const flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');
    const defaultUrl = flavor == 'prod'
        ? 'https://shop.example.com'
        : 'http://10.0.2.2';
    const apiNamespace = String.fromEnvironment(
      'API_NAMESPACE',
      defaultValue: 'storefuse/v1',
    );
    const rawBridgeBaseUrl = String.fromEnvironment(
      'BRIDGE_BASE_URL',
      defaultValue: defaultUrl,
    );
    return AppEnv._(
      bridgeBaseUrl: normalizeBridgeBaseUrl(rawBridgeBaseUrl, apiNamespace),
      apiNamespace: apiNamespace,
      flavor: flavor,
      deepLinkScheme: const String.fromEnvironment(
        'STOREFRONT_DEEP_LINK_SCHEME',
        defaultValue: 'storefuse',
      ),
      enableHttpLogs: const bool.fromEnvironment(
        'ENABLE_HTTP_LOGS',
        defaultValue: false,
      ),
    );
  }

  /// Android emulator reaches the development machine through its host alias.
  String resolveStoreUrl(String value) {
    if (isProd) return value;
    final base = Uri.tryParse(bridgeBaseUrl);
    final url = Uri.tryParse(value);
    if (base?.host == '10.0.2.2' &&
        url != null &&
        {'localhost', '127.0.0.1'}.contains(url.host) &&
        {'http', 'https'}.contains(url.scheme) &&
        url.port == base!.port) {
      return url.replace(host: base.host).toString();
    }
    return value;
  }

  void validate() {
    if (isProd && !bridgeBaseUrl.startsWith('https://')) {
      throw StateError('APP_FLAVOR=prod requires HTTPS BRIDGE_BASE_URL');
    }
    if (isProd && enableHttpLogs) {
      throw StateError('ENABLE_HTTP_LOGS is not allowed when APP_FLAVOR=prod');
    }
  }
}
