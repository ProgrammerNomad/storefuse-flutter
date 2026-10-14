import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/bootstrap/app_ui_config.dart';
import '../models/json_helpers.dart';
import 'sale_badge.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.cardConfig = ProductCardUiConfig.defaults,
  });

  final JsonMap product;
  final ProductCardUiConfig cardConfig;

  @override
  Widget build(BuildContext context) {
    final slug = product['slug'] as String? ?? '';
    final name = product['name'] as String? ?? 'Product';
    final price = priceFormatted(asJsonMap(product['price']));
    final onSale = productOnSale(product);
    final regular = priceFormatted(asJsonMap(product['regular_price']));
    final stockKnown =
        product.containsKey('is_in_stock') ||
        product['stock_status'] != null;
    final inStock = productInStock(product);
    final thumb = productThumbnailUrl(product);
    final rating = _productRating(product);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: slug.isEmpty ? null : () => context.push('/products/$slug'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb != null)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.image_not_supported_outlined),
                    )
                  else
                    ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  if (cardConfig.showSaleBadge && onSale)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: SaleBadge(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (cardConfig.showRating && rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(price, style: Theme.of(context).textTheme.titleSmall),
                  if (onSale && regular.isNotEmpty)
                    Text(
                      regular,
                      semanticsLabel: 'Original price $regular',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (cardConfig.showStockBadge && stockKnown && !inStock)
                    Text(
                      'Out of stock',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _productRating(JsonMap product) {
    final avg = product['average_rating'] ?? product['rating'];
    if (avg is num && avg > 0) return avg.toDouble();
    if (avg is String) {
      final parsed = double.tryParse(avg);
      if (parsed == null || parsed <= 0) return null;
      return parsed;
    }
    return null;
  }
}
