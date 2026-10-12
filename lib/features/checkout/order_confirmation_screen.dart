import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../orders/orders_repository.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({super.key, required this.orderKey});

  final String orderKey;

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(ordersRepositoryProvider).byKey(widget.orderKey);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Order confirmed',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _future = ref.read(ordersRepositoryProvider).byKey(widget.orderKey);
              }),
            );
          }
          final order = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thank you!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Order #${order['number'] ?? order['id']}'),
                Text('Status: ${order['status']}'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue shopping'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
