/// Custom-scheme links handled by [GoRouter] redirect in `app_router.dart`.
class StoreDeepLinks {
  StoreDeepLinks._();

  static Uri productUri({required String scheme, required String slug}) {
    return Uri(scheme: scheme, host: 'product', pathSegments: [slug]);
  }

  /// Share text: app deep link plus optional web permalink for users without the app.
  static String productShareText({
    required String scheme,
    required String slug,
    String? webPermalink,
  }) {
    final appLink = productUri(scheme: scheme, slug: slug).toString();
    final web = webPermalink?.trim();
    if (web != null && web.startsWith('http')) {
      return '$appLink\n$web';
    }
    return appLink;
  }
}
