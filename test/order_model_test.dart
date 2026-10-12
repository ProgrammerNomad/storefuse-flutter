import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/models/order.dart';

void main() {
  test('Order parses line items and totals', () {
    final order = Order.fromJson({
      'id': 42,
      'number': '10042',
      'status': 'processing',
      'total': {'formatted': '₹999'},
      'items': [
        {
          'name': 'Widget',
          'quantity': 2,
          'total': {'formatted': '₹999'},
        },
      ],
      'billing': {'first_name': 'Ada', 'city': 'Pune'},
    });

    expect(order.id, 42);
    expect(order.lineItems.length, 1);
    expect(order.lineItems.first.name, 'Widget');
    expect(order.totalFormatted, '₹999');
    expect(order.billing?['city'], 'Pune');
  });
}
