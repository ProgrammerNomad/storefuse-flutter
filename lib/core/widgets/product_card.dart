import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/json_helpers.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final JsonMap product;

  @override
  Widget build(BuildContext context) {
    final slug = product['slug'] as String? ?? '';
    final name = product['name'] as String? ?? 'Product';
    final price = priceFormatted(asJsonMap(product['price']));
    final onSale = productOnSale(product);
    final regular = priceFormatted(asJsonMap(product['regular_price']));
    final inStock = productInStock(product);
    final thumb = productThumbnailUrl(product);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: slug.isEmpty ? null : () => context.push('/product/$slug'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: thumb != null
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.image_not_supported_outlined),
                    )
                  : ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                  if (!inStock)
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
}
