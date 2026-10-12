import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/features/cart/cart_provider.dart';

void main() {
  test('CartState itemCount parses envelope fields', () {
    const state = CartState(data: {'item_count': 3});
    expect(state.itemCount, 3);
  });

  test('CartState itemCount defaults to zero', () {
    expect(const CartState().itemCount, 0);
  });
}
