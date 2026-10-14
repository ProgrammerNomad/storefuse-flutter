import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/features/bootstrap/app_ui_config.dart';

void main() {
  test('AppUiConfig defaults to grid catalog with two columns', () {
    const config = AppUiConfig();
    expect(config.catalog.layout, CatalogLayout.grid);
    expect(config.catalog.columns, 2);
    expect(config.productCard.showStockBadge, isTrue);
  });

  test('AppUiConfig.fromSettings parses catalog layout and screen overrides', () {
    final config = AppUiConfig.fromSettings({
      'app': {
        'ui': {
          'catalog': {'layout': 'list', 'columns': 3},
          'product_card': {
            'show_stock_badge': false,
            'show_rating': true,
            'show_sale_badge': false,
          },
          'screens': {
            'shop': {'title': 'Browse'},
            'search': {'layout': 'grid'},
            'product': {'show_sku': true, 'related_count': 6},
            'cart': {
              'show_free_shipping_bar': false,
              'empty_cta_href': '/home',
            },
          },
        },
      },
    });

    expect(config.catalog.layout, CatalogLayout.list);
    expect(config.catalog.columns, 3);
    expect(config.productCard.showStockBadge, isFalse);
    expect(config.productCard.showRating, isTrue);
    expect(config.screenTitle('shop'), 'Browse');
    expect(config.catalogForScreen('search').layout, CatalogLayout.grid);
    expect(config.productScreen.showSku, isTrue);
    expect(config.productScreen.relatedCount, 6);
    expect(config.cartScreen.showFreeShippingBar, isFalse);
    expect(config.cartScreen.emptyCtaHref, '/home');
  });

  test('parseCatalogLayout maps list and grid strings', () {
    expect(parseCatalogLayout('grid'), CatalogLayout.grid);
    expect(parseCatalogLayout('LIST'), CatalogLayout.list);
    expect(parseCatalogLayout(null), CatalogLayout.grid);
    expect(
      parseCatalogLayout('unknown', fallback: CatalogLayout.list),
      CatalogLayout.list,
    );
  });

  test('missing app.ui uses documented defaults', () {
    final config = AppUiConfig.fromSettings({'app': {'primary_color': '#fff'}});
    expect(config.catalogForScreen('shop').layout, CatalogLayout.grid);
    expect(config.catalogForScreen('shop').columns, 2);
  });

  test('Bridge app.ui uses screens.home.hide_sections', () {
    final config = AppUiConfig.fromSettings({
      'app': {
        'ui': {
          'catalog': {'layout': 'grid', 'columns': 2, 'show_stock_badge': true},
          'screens': {
            'home': {
              'section_order': ['hero', 'best_sellers'],
              'hide_sections': ['promo_banner'],
            },
          },
        },
      },
    });
    expect(config.homeSectionOrder.first, 'hero');
    expect(config.isHomeSectionVisible('promo_banner'), isFalse);
    expect(config.isHomeSectionVisible('hero'), isTrue);
  });
}
