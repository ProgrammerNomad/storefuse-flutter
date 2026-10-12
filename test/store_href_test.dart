import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/routing/store_href.dart';

void main() {
  test('storeHrefToRoute maps shop paths', () {
    expect(storeHrefToRoute('/shop'), '/products');
    expect(storeHrefToRoute('/category/shoes'), '/categories/shoes');
    expect(storeHrefToRoute('/product/widget'), '/products/widget');
  });
}
