import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/models/order.dart';
import '../../core/ui/show_store_error.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/order_status_badge.dart';
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
          final order = Order.fromJson(snapshot.data!);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Order #${order.number}', style: Theme.of(context).textTheme.titleLarge),
              OrderStatusBadge(status: order.status ?? ''),
              if (order.dateCreated != null) Text(order.dateCreated!),
              if (order.totalFormatted != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Total: ${order.totalFormatted}'),
                ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              ...order.lineItems.map(
                (line) => ListTile(
                  title: Text(line.name),
                  subtitle: Text('Qty ${line.quantity}'),
                  trailing: Text(line.totalFormatted ?? ''),
                ),
              ),
              if (order.billing != null) ...[
                const SizedBox(height: 16),
                Text('Billing', style: Theme.of(context).textTheme.titleMedium),
                Text(_formatAddress(order.billing!)),
              ],
              if (order.shipping != null) ...[
                const SizedBox(height: 16),
                Text('Shipping', style: Theme.of(context).textTheme.titleMedium),
                Text(_formatAddress(order.shipping!)),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_canCancel(order.status ?? ''))
                    OutlinedButton(
                      onPressed: () async {
                        final ok = await showConfirmDialog(
                          context,
                          title: 'Cancel order?',
                          message: 'This will request cancellation for this order.',
                        );
                        if (!ok || !context.mounted) return;
                        try {
                          await ref.read(ordersRepositoryProvider).cancel(widget.orderId);
                          await _reload();
                        } on StoreFuseApiException catch (e) {
                          SnackBarHelper.showException(context, e);
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(ordersRepositoryProvider).reorder(widget.orderId);
                        await ref.read(cartProvider.notifier).refresh();
                        SnackBarHelper.showMessage(context, 'Items added to cart');
                      } on StoreFuseApiException catch (e) {
                        SnackBarHelper.showException(context, e);
                      }
                    },
                    child: const Text('Reorder'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final reason = await _promptReturnReason(context);
                      if (reason == null || !context.mounted) return;
                      try {
                        await ref.read(ordersRepositoryProvider).returnRequest(
                              widget.orderId,
                              reason: reason,
                            );
                        SnackBarHelper.showMessage(context, 'Return requested');
                      } on StoreFuseApiException catch (e) {
                        SnackBarHelper.showException(context, e);
                      }
                    },
                    child: const Text('Return'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final invoice =
                            await ref.read(ordersRepositoryProvider).invoice(widget.orderId);
                        final url = invoice['url']?.toString() ??
                            invoice['invoice_url']?.toString() ??
                            invoice['print_url']?.toString();
                        if (url == null || url.isEmpty) {
                          if (context.mounted) {
                            SnackBarHelper.showMessage(context, 'Invoice not available.');
                          }
                          return;
                        }
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      } on StoreFuseApiException catch (e) {
                        SnackBarHelper.showException(context, e);
                      }
                    },
                    child: const Text('Invoice'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final t = await ref.read(ordersRepositoryProvider).tracking(widget.orderId);
                        if (!context.mounted) return;
                        await showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Tracking'),
                            content: Text(_trackingText(t)),
                          ),
                        );
                      } on StoreFuseApiException catch (e) {
                        SnackBarHelper.showException(context, e);
                      }
                    },
                    child: const Text('Tracking'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  bool _canCancel(String status) {
    final s = status.toLowerCase();
    return s == 'pending' || s == 'processing' || s == 'on-hold';
  }

  String _formatAddress(JsonMap a) {
    return [
      a['first_name'],
      a['last_name'],
      a['address_1'],
      a['city'],
      a['postcode'],
      a['country'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }

  String _trackingText(JsonMap t) {
    final url = t['tracking_url']?.toString() ?? t['url']?.toString();
    final provider = t['carrier']?.toString() ?? t['provider']?.toString();
    final number = t['tracking_number']?.toString() ?? t['number']?.toString();
    return [provider, number, url].whereType<String>().where((s) => s.isNotEmpty).join('\n');
  }

  Future<String?> _promptReturnReason(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Why are you returning?'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
