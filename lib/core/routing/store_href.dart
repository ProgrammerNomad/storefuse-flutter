/// Maps Bridge navigation/homepage hrefs to in-app GoRouter paths.
String? storeHrefToRoute(String href) {
  if (href.isEmpty) return null;
  var path = href.trim();
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return null;
  }
  if (!path.startsWith('/')) path = '/$path';

  if (path == '/' || path == '/home') return '/home';
  if (path == '/shop' || path == '/products') return '/products';
  if (path.startsWith('/product/')) {
    final slug = path.replaceFirst('/product/', '');
    return slug.isEmpty ? null : '/products/$slug';
  }
  if (path.startsWith('/products/')) return path;
  if (path.startsWith('/category/')) {
    final slug = path.replaceFirst('/category/', '');
    return slug.isEmpty ? null : '/categories/$slug';
  }
  if (path.startsWith('/categories/')) return path;
  if (path == '/cart') return '/cart';
  if (path == '/checkout') return '/checkout';
  if (path == '/account') return '/account';
  if (path == '/orders') return '/orders';
  if (path == '/search') return '/search';
  if (path == '/categories') return '/categories';
  return null;
}

/// Alias used by homepage/navigation widgets.
String? storeHrefToAppPath(String href) => storeHrefToRoute(href);
