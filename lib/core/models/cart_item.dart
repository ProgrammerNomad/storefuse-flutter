import 'json_helpers.dart';

class CartItem {
  const CartItem({
    required this.key,
    required this.quantity,
    this.product,
    this.price,
  });

  final String key;
  final int quantity;
  final JsonMap? product;
  final JsonMap? price;

  factory CartItem.fromJson(JsonMap json) {
    return CartItem(
      key: json['key']?.toString() ?? '',
      quantity: parseInt(json['quantity'], fallback: 1),
      product: asJsonMap(json['product']) ?? json,
      price: asJsonMap(json['price']),
    );
  }
}

class CartSummary {
  const CartSummary({this.items = const [], this.totals, this.itemCount = 0});

  final List<CartItem> items;
  final JsonMap? totals;
  final int itemCount;

  factory CartSummary.fromJson(JsonMap json) {
    return CartSummary(
      items: asJsonList(json['items']).map(CartItem.fromJson).toList(),
      totals: asJsonMap(json['totals']),
      itemCount: parseInt(json['item_count']),
    );
  }
}
