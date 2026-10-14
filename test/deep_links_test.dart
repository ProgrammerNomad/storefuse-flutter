import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/deep_links.dart';

void main() {
  test('productUri uses product host and slug path', () {
    expect(
      StoreDeepLinks.productUri(scheme: 'mystore', slug: 'blue-widget').toString(),
      'mystore://product/blue-widget',
    );
  });

  test('categoryUri uses category host and slug path', () {
    expect(
      StoreDeepLinks.categoryUri(scheme: 'mystore', slug: 'clothing').toString(),
      'mystore://category/clothing',
    );
  });

  test('orderUri uses order host and orderId path', () {
    expect(
      StoreDeepLinks.orderUri(scheme: 'mystore', orderId: '1024').toString(),
      'mystore://order/1024',
    );
  });
}
