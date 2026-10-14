import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/models/json_helpers.dart';

void main() {
  test('asStringList parses string IDs from Bridge arrays', () {
    expect(asStringList(['hero', 'featured', 'promo']), [
      'hero',
      'featured',
      'promo',
    ]);
    expect(asStringList(['cod', 'bacs', 'cheque']), [
      'cod',
      'bacs',
      'cheque',
    ]);
    expect(asStringList(null), isEmpty);
    expect(asStringList('not-a-list'), isEmpty);
    expect(asStringList(['', 'visible']), ['visible']);
  });

  test('asJsonList still maps object lists only', () {
    final objects = asJsonList([
      {'id': 'flat_rate:1', 'label': 'Flat'},
    ]);
    expect(objects.length, 1);
    expect(objects.first['id'], 'flat_rate:1');
    expect(
      () => asJsonList(['cod', 'bacs']),
      throwsA(isA<TypeError>()),
    );
  });

  test('productThumbnailUrl resolves thumbnail images and image', () {
    expect(
      productThumbnailUrl({
        'thumbnail': {'url': 'https://example.com/t.jpg'},
      }),
      'https://example.com/t.jpg',
    );
    expect(
      productThumbnailUrl({
        'images': [
          {'src': 'https://example.com/i.jpg'},
        ],
      }),
      'https://example.com/i.jpg',
    );
  });

  test('matchProductVariationId matches WC attribute map', () {
    final id = matchProductVariationId(
      variations: [
        {
          'id': '42',
          'attributes': {'attribute_pa_color': 'blue', 'attribute_pa_size': 'large'},
        },
      ],
      productAttributes: [
        {'name': 'Color', 'slug': 'pa_color'},
        {'name': 'Size', 'slug': 'pa_size'},
      ],
      selectedOptions: {'Color': 'Blue', 'Size': 'Large'},
    );
    expect(id, 42);
  });

  test('variationOptionIsAvailable hides impossible combinations', () {
    const variations = [
      {
        'id': '1',
        'purchasable': true,
        'stock_status': 'instock',
        'attributes': {'attribute_pa_color': 'red', 'attribute_pa_size': 's'},
      },
      {
        'id': '2',
        'purchasable': true,
        'stock_status': 'instock',
        'attributes': {'attribute_pa_color': 'blue', 'attribute_pa_size': 'm'},
      },
    ];
    const attrs = [
      {'name': 'Color', 'slug': 'pa_color', 'variation': true},
      {'name': 'Size', 'slug': 'pa_size', 'variation': true},
    ];

    expect(
      variationOptionIsAvailable(
        variations: variations,
        productAttributes: attrs,
        attributeName: 'Size',
        optionValue: 'm',
        selectedOptions: {'Color': 'Red'},
      ),
      isFalse,
    );
    expect(
      variationOptionIsAvailable(
        variations: variations,
        productAttributes: attrs,
        attributeName: 'Size',
        optionValue: 's',
        selectedOptions: {'Color': 'Red'},
      ),
      isTrue,
    );
  });

  test('productInStock prefers is_in_stock when key present', () {
    expect(
      productInStock({
        'is_in_stock': false,
        'stock_status': 'instock',
      }),
      isFalse,
    );
    expect(
      productInStock({
        'is_in_stock': true,
        'stock_status': 'outofstock',
      }),
      isTrue,
    );
  });

  test('productInStock falls back to stock_status when is_in_stock absent', () {
    expect(
      productInStock({'stock_status': 'instock'}),
      isTrue,
    );
    expect(
      productInStock({'stock_status': 'onbackorder'}),
      isTrue,
    );
    expect(
      productInStock({'stock_status': 'outofstock'}),
      isFalse,
    );
    expect(productInStock({}), isFalse);
  });

  test('productInStock treats summary payload with is_in_stock as in stock', () {
    expect(
      productInStock({
        'slug': 'hat',
        'name': 'Hat',
        'is_in_stock': true,
        'stock_status': 'instock',
      }),
      isTrue,
    );
  });

  test('productOnSale uses regular and sale price when on_sale missing', () {
    expect(
      productOnSale({
        'regular_price': {'raw': 100},
        'sale_price': {'raw': 80},
      }),
      isTrue,
    );
    expect(
      productOnSale({
        'regular_price': {'raw': 100},
        'sale_price': {'raw': 100},
      }),
      isFalse,
    );
  });

  test('shippingMethodsFromCheckoutData flattens packages', () {
    final methods = shippingMethodsFromCheckoutData({
      'packages': [
        {
          'index': 0,
          'methods': [
            {'id': 'flat_rate:1', 'label': 'Flat'},
          ],
        },
      ],
    });
    expect(methods.length, 1);
    expect(methods.first['id'], 'flat_rate:1');
  });
}
