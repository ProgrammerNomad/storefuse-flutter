import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/price_text.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final data = cart.data;
    final items = asJsonList(data?['items']);
    final totals = asJsonMap(data?['totals']);

    return AppScaffold(
      title: 'Cart',
      body: cart.loading && data == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (cart.error != null)
                  MaterialBanner(
                    content: Text(cart.error!.message),
                    actions: [
                      TextButton(
                        onPressed: () => ref.read(cartProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('Your cart is empty.'))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final line = items[index];
                            final key = line['key'] as String? ?? '';
                            final product = asJsonMap(line['product']) ?? line;
                            final qty = parseInt(line['quantity'], fallback: 1);
                            return ListTile(
                              title: Text(product['name']?.toString() ?? 'Item'),
                              subtitle: PriceText(price: asJsonMap(line['price'] ?? product['price'])),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateLine(key: key, quantity: qty - 1),
                                  ),
                                  Text('$qty'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateLine(key: key, quantity: qty + 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        ref.read(cartProvider.notifier).removeLine(key),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: const InputDecoration(labelText: 'Coupon code'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          try {
                            await ref
                                .read(cartProvider.notifier)
                                .applyCoupon(_couponController.text.trim());
                          } on StoreFuseApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (totals != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total'),
                        PriceText(price: asJsonMap(totals['total'])),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: items.isEmpty ? null : () => context.push('/checkout'),
                    child: const Text('Checkout'),
                  ),
                ),
              ],
            ),
    );
  }
}
