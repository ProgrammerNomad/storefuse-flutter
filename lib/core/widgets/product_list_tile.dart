import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/json_helpers.dart';
import 'cached_thumbnail.dart';
import 'price_text.dart';
import 'stock_badge.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({super.key, required this.product});

  final JsonMap product;

  @override
  Widget build(BuildContext context) {
    final slug = product['slug']?.toString() ?? '';
    return ListTile(
      leading: _thumb(product),
      title: Text(product['name']?.toString() ?? slug),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PriceText(price: asJsonMap(product['price'])),
          const SizedBox(height: 4),
          StockBadge(product: product),
        ],
      ),
      isThreeLine: true,
      onTap: slug.isEmpty ? null : () => context.push('/products/$slug'),
    );
  }

  Widget _thumb(JsonMap p) {
    final url = productThumbnailUrl(p);
    return cachedThumbnail(
      url: url,
      size: 56,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
