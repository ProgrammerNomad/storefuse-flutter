import 'json_helpers.dart';

class OrderLineItem {
  const OrderLineItem({
    required this.name,
    required this.quantity,
    this.subtotal,
    this.total,
    this.product,
  });

  final String name;
  final int quantity;
  final JsonMap? subtotal;
  final JsonMap? total;
  final JsonMap? product;

  factory OrderLineItem.fromJson(JsonMap json) {
    return OrderLineItem(
      name: json['name']?.toString() ?? '',
      quantity: parseInt(json['quantity'], fallback: 1),
      subtotal: asJsonMap(json['subtotal']),
      total: asJsonMap(json['total']),
      product: asJsonMap(json['product']),
    );
  }

  String? get totalFormatted => priceFormatted(total ?? subtotal);
}

class Order {
  const Order({
    required this.id,
    this.number,
    this.status,
    this.dateCreated,
    this.items = const [],
    this.totals,
    this.billing,
    this.shipping,
  });

  final int id;
  final String? number;
  final String? status;
  final String? dateCreated;
  final List<OrderLineItem> items;
  final JsonMap? totals;
  final JsonMap? billing;
  final JsonMap? shipping;

  List<OrderLineItem> get lineItems => items;

  String? get totalFormatted => priceFormatted(asJsonMap(totals?['total']));

  factory Order.fromJson(JsonMap json) {
    var totals = asJsonMap(json['totals']);
    if (totals == null && json['total'] is Map) {
      totals = {'total': json['total']};
    }
    return Order(
      id: parseInt(json['id']),
      number: json['number']?.toString(),
      status: json['status']?.toString(),
      dateCreated: json['date_created']?.toString(),
      items: asJsonList(
        json['items'] ?? json['line_items'],
      ).map(OrderLineItem.fromJson).toList(),
      totals: totals,
      billing: asJsonMap(json['billing']),
      shipping: asJsonMap(json['shipping']),
    );
  }
}
