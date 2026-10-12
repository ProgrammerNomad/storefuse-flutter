/// Runtime configuration via `--dart-define`.
class AppEnv {
  AppEnv._({
    required this.bridgeBaseUrl,
    required this.apiNamespace,
    required this.flavor,
    required this.deepLinkScheme,
    required this.enableHttpLogs,
  });

  static const minSupportedBridgeVersion = '1.0.2';

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
  Duration get connectTimeout => isProd ? const Duration(seconds: 30) : const Duration(seconds: 10);

  Duration get receiveTimeout => isProd ? const Duration(seconds: 30) : const Duration(seconds: 10);

  static AppEnv fromDartDefines() {
    const flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');
    const defaultUrl = flavor == 'prod'
        ? 'https://shop.example.com'
        : 'http://10.0.2.2';
    return AppEnv._(
      bridgeBaseUrl: const String.fromEnvironment(
        'BRIDGE_BASE_URL',
        defaultValue: defaultUrl,
      ),
      apiNamespace: const String.fromEnvironment(
        'API_NAMESPACE',
        defaultValue: 'storefuse/v1',
      ),
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

  void validate() {
    if (isProd && !bridgeBaseUrl.startsWith('https://')) {
      throw StateError('APP_FLAVOR=prod requires HTTPS BRIDGE_BASE_URL');
    }
  }
}
