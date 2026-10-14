import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/deep_links.dart';

void main() {
  test('productUri uses product host and slug path', () {
    expect(
      StoreDeepLinks.productUri(scheme: 'mystore', slug: 'blue-widget').toString(),
      'mystore://product/blue-widget',
    );
  });

  test('productShareText includes web permalink when provided', () {
    final text = StoreDeepLinks.productShareText(
      scheme: 'storefuse',
      slug: 'tee',
      webPermalink: 'https://shop.example.com/product/tee/',
    );
    expect(text, contains('storefuse://product/tee'));
    expect(text, contains('https://shop.example.com/product/tee/'));
  });
}
