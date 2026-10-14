import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_helpers.dart';
import 'bootstrap_provider.dart';

enum CatalogLayout { grid, list }

CatalogLayout parseCatalogLayout(
  dynamic value, {
  CatalogLayout fallback = CatalogLayout.grid,
}) {
  final v = value?.toString().toLowerCase();
  if (v == 'list') return CatalogLayout.list;
  if (v == 'grid') return CatalogLayout.grid;
  return fallback;
}

class CatalogListUiConfig {
  const CatalogListUiConfig({
    required this.layout,
    required this.columns,
  });

  final CatalogLayout layout;
  final int columns;

  static const defaults = CatalogListUiConfig(
    layout: CatalogLayout.grid,
    columns: 2,
  );

  double childAspectRatioFor(int columnCount) {
    if (columnCount >= 3) return 0.65;
    return 0.72;
  }
}

class ProductCardUiConfig {
  const ProductCardUiConfig({
    required this.showStockBadge,
    required this.showRating,
    required this.showSaleBadge,
  });

  final bool showStockBadge;
  final bool showRating;
  final bool showSaleBadge;

  static const defaults = ProductCardUiConfig(
    showStockBadge: true,
    showRating: true,
    showSaleBadge: true,
  );
}

class ProductScreenUiConfig {
  const ProductScreenUiConfig({
    required this.showSku,
    required this.stickyAddToCart,
    required this.relatedCount,
  });

  final bool showSku;
  final bool stickyAddToCart;
  final int relatedCount;

  static const defaults = ProductScreenUiConfig(
    showSku: true,
    stickyAddToCart: false,
    relatedCount: 6,
  );
}

class CartScreenUiConfig {
  const CartScreenUiConfig({
    required this.showCoupon,
    required this.showFreeShippingBar,
    required this.emptyCtaHref,
  });

  final bool showCoupon;
  final bool showFreeShippingBar;
  final String emptyCtaHref;

  static const defaults = CartScreenUiConfig(
    showCoupon: true,
    showFreeShippingBar: true,
    emptyCtaHref: '/products',
  );
}

/// Parsed `settings.app.ui` (storefuse.app-ui.v1).
class AppUiConfig {
  const AppUiConfig({
    this.catalog = CatalogListUiConfig.defaults,
    this.productCard = ProductCardUiConfig.defaults,
    this.productScreen = ProductScreenUiConfig.defaults,
    this.cartScreen = CartScreenUiConfig.defaults,
    this.shopTitle = 'Products',
    this.searchLayout,
    this.homeSectionOrder = _defaultHomeOrder,
    this.homeHiddenSections = const {},
  });

  static const _defaultHomeOrder = [
    'announcement_bar',
    'hero',
    'featured_categories',
    'trust_items',
    'best_sellers',
    'new_arrivals',
    'promo_banner',
  ];

  final CatalogListUiConfig catalog;
  final ProductCardUiConfig productCard;
  final ProductScreenUiConfig productScreen;
  final CartScreenUiConfig cartScreen;
  final String shopTitle;
  final CatalogLayout? searchLayout;
  final List<String> homeSectionOrder;
  final Set<String> homeHiddenSections;

  factory AppUiConfig.fromSettings(JsonMap? settingsData) {
    final app = asJsonMap(settingsData?['app']);
    return AppUiConfig.fromJson(asJsonMap(app?['ui']));
  }

  factory AppUiConfig.fromJson(JsonMap? raw) {
    if (raw == null || raw.isEmpty) return const AppUiConfig();

    final catalogMap = asJsonMap(raw['catalog']) ?? {};
    final cardMap = asJsonMap(raw['product_card']) ?? catalogMap;
    final screens = asJsonMap(raw['screens']) ?? {};
    final shop = asJsonMap(screens['shop']) ?? {};
    final search = asJsonMap(screens['search']) ?? {};
    final product = asJsonMap(screens['product']) ?? {};
    final cart = asJsonMap(screens['cart']) ?? {};
    final home =
        asJsonMap(screens['home']) ?? asJsonMap(raw['home']) ?? {};

    final catalogLayout = parseCatalogLayout(catalogMap['layout']);
    final columns = parseInt(catalogMap['columns'], fallback: 2).clamp(1, 3);

    CatalogLayout? searchOverride;
    final searchLayoutRaw = search['layout']?.toString();
    if (searchLayoutRaw != null && searchLayoutRaw.isNotEmpty) {
      searchOverride = parseCatalogLayout(searchLayoutRaw);
    }

    final orderRaw = home['section_order'];
    final order = orderRaw is List
        ? orderRaw.map((e) => e.toString()).toList()
        : _defaultHomeOrder;

    final hiddenRaw = home['hide_sections'] ?? home['hidden'];
    final hidden = hiddenRaw is List
        ? hiddenRaw.map((e) => e.toString()).toSet()
        : const <String>{};

    return AppUiConfig(
      catalog: CatalogListUiConfig(
        layout: catalogLayout,
        columns: columns,
      ),
      productCard: ProductCardUiConfig(
        showStockBadge: (cardMap['show_stock_badge'] ??
                catalogMap['show_stock_badge']) !=
            false,
        showRating: cardMap['show_rating'] != false,
        showSaleBadge: cardMap['show_sale_badge'] != false,
      ),
      productScreen: ProductScreenUiConfig(
        showSku: product['show_sku'] != false,
        stickyAddToCart: product['sticky_add_to_cart'] == true,
        relatedCount: parseInt(
          product['related_count'],
          fallback: ProductScreenUiConfig.defaults.relatedCount,
        ).clamp(0, 12),
      ),
      cartScreen: CartScreenUiConfig(
        showCoupon: cart['show_coupon'] != false,
        showFreeShippingBar: cart['show_free_shipping_bar'] != false,
        emptyCtaHref:
            cart['empty_cta_href']?.toString() ??
            CartScreenUiConfig.defaults.emptyCtaHref,
      ),
      shopTitle: shop['title']?.toString() ?? 'Products',
      searchLayout: searchOverride,
      homeSectionOrder: order.isEmpty ? _defaultHomeOrder : order,
      homeHiddenSections: hidden,
    );
  }

  CatalogListUiConfig catalogForScreen(String screen) {
    if (screen == 'search' && searchLayout != null) {
      return CatalogListUiConfig(
        layout: searchLayout!,
        columns: catalog.columns,
      );
    }
    return catalog;
  }

  String? screenTitle(String screen) {
    if (screen == 'shop') return shopTitle;
    return null;
  }

  bool isHomeSectionVisible(String id) => !homeHiddenSections.contains(id);
}

final appUiConfigProvider = Provider<AppUiConfig>((ref) {
  final settings = ref.watch(bootstrapProvider).valueOrNull?.settingsData;
  return AppUiConfig.fromSettings(settings);
});
