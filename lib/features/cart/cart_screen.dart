import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/ui/show_store_error.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
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

  Future<void> _refresh() => ref.read(cartProvider.notifier).refresh();

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
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EmptyStateView(
                                title: 'Your cart is empty',
                                actionLabel: 'Continue shopping',
                                onAction: () => context.go('/products'),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final line = items[index];
                              final key = line['key'] as String? ?? '';
                              final product = asJsonMap(line['product']) ?? line;
                              final qty = parseInt(line['quantity'], fallback: 1);
                              final thumb = imageUrl(asJsonMap(product['thumbnail'])) ??
                                  (product['images'] is List && (product['images'] as List).isNotEmpty
                                      ? imageUrl(asJsonMap((product['images'] as List).first))
                                      : null);
                              return Dismissible(
                                key: ValueKey(key),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Theme.of(context).colorScheme.error,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) =>
                                    ref.read(cartProvider.notifier).removeLine(key),
                                child: ListTile(
                                  leading: thumb != null
                                      ? Image.network(thumb, width: 48, height: 48, fit: BoxFit.cover)
                                      : const Icon(Icons.image_outlined),
                                  title: Text(product['name']?.toString() ?? 'Item'),
                                  subtitle: PriceText(
                                    price: asJsonMap(line['price'] ?? product['price']),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: qty <= 1
                                            ? () => ref.read(cartProvider.notifier).removeLine(key)
                                            : () => ref
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
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                if (items.isNotEmpty) ...[
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
                              if (context.mounted) SnackBarHelper.showException(context, e);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  if (totals != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          PriceText(price: asJsonMap(totals['subtotal'])),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total'),
                          PriceText(price: asJsonMap(totals['total'])),
                        ],
                      ),
                    ),
                  ],
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.push('/checkout'),
                          child: const Text('Checkout'),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
