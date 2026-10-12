import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../cart/cart_provider.dart';
import 'orders_repository.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Future<JsonMap> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(ordersRepositoryProvider).byId(widget.orderId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = ref.read(ordersRepositoryProvider).byId(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Order',
      body: FutureBuilder<JsonMap>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final order = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Order #${order['number'] ?? order['id']}'),
              Text('Status: ${order['status']}'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(ordersRepositoryProvider).cancel(widget.orderId);
                        await _reload();
                      } on StoreFuseApiException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(ordersRepositoryProvider).reorder(widget.orderId);
                        await ref.read(cartProvider.notifier).refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Items added to cart')),
                        );
                      } on StoreFuseApiException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                    child: const Text('Reorder'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(ordersRepositoryProvider).returnRequest(
                              widget.orderId,
                              reason: 'App return request',
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Return requested')),
                        );
                      } on StoreFuseApiException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                    child: const Text('Return'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final t = await ref
                            .read(ordersRepositoryProvider)
                            .tracking(widget.orderId);
                        if (context.mounted) {
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Tracking'),
                              content: Text(t.toString()),
                            ),
                          );
                        }
                      } on StoreFuseApiException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                    child: const Text('Tracking'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final inv = await ref
                            .read(ordersRepositoryProvider)
                            .invoice(widget.orderId);
                        if (context.mounted) {
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Invoice'),
                              content: Text(inv.toString()),
                            ),
                          );
                        }
                      } on StoreFuseApiException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                    child: const Text('Invoice'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
