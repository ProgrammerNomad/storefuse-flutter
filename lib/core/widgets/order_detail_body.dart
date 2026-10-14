import 'package:flutter/material.dart';

import '../models/address.dart';
import '../models/json_helpers.dart';
import 'order_status_badge.dart';
import 'price_text.dart';

class OrderDetailBody extends StatelessWidget {
  const OrderDetailBody({super.key, required this.order});

  final JsonMap order;

  @override
  Widget build(BuildContext context) {
    final items = asJsonList(order['items']);
    final totals = asJsonMap(order['totals']);
    final billing = Address.fromJson(asJsonMap(order['billing']) ?? {});
    final shipping = Address.fromJson(asJsonMap(order['shipping']) ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Order #${order['number'] ?? order['id']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OrderStatusBadge(status: order['status']?.toString()),
          ],
        ),
        if (order['date_created'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(order['date_created'].toString()),
          ),
        const SizedBox(height: 20),
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...items.map((line) {
          final product = asJsonMap(line['product']);
          final thumb = product != null
              ? imageUrl(asJsonMap(product['thumbnail']))
              : null;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: thumb != null
                ? Image.network(thumb, width: 48, height: 48, fit: BoxFit.cover)
                : const Icon(Icons.shopping_bag_outlined),
            title: Text(line['name']?.toString() ?? 'Item'),
            subtitle: Text('Qty: ${line['quantity']}'),
            trailing: PriceText(
              price: asJsonMap(line['total'] ?? line['subtotal']),
            ),
          );
        }),
        const Divider(height: 32),
        if (totals != null) ...[
          Text('Totals', style: Theme.of(context).textTheme.titleMedium),
          _totalRow('Subtotal', totals['subtotal']),
          _totalRow('Shipping', totals['shipping']),
          _totalRow('Tax', totals['tax']),
          _totalRow('Total', totals['total'], bold: true),
          const SizedBox(height: 16),
        ],
        Text('Billing', style: Theme.of(context).textTheme.titleMedium),
        Text(billing.formattedLines),
        const SizedBox(height: 12),
        Text('Shipping', style: Theme.of(context).textTheme.titleMedium),
        Text(shipping.formattedLines),
      ],
    );
  }

  Widget _totalRow(String label, dynamic price, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          PriceText(price: asJsonMap(price)),
        ],
      ),
    );
  }
}
