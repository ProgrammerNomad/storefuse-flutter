import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/models/json_helpers.dart';

void main() {
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
