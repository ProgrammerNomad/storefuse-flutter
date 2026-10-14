import 'package:flutter/material.dart';

import '../models/json_helpers.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, this.product, this.inStock})
    : assert(product != null || inStock != null);

  final JsonMap? product;
  final bool? inStock;

  @override
  Widget build(BuildContext context) {
    final stocked = inStock ?? productInStock(product ?? const {});
    final color = stocked ? Colors.green.shade700 : Colors.red.shade700;
    final bg = stocked ? Colors.green.shade50 : Colors.red.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        stocked ? 'In stock' : 'Out of stock',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
