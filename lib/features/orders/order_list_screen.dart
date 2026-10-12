import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import '../auth/auth_session_provider.dart';
import 'orders_repository.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  late Future<List<JsonMap>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(ordersRepositoryProvider).list();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);

    if (!loggedIn) {
      return AppScaffold(
        title: 'Orders',
        body: Center(
          child: FilledButton(
            onPressed: () => context.push('/auth/login'),
            child: const Text('Sign in to view orders'),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Orders',
      body: FutureBuilder<List<JsonMap>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(_load),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final o = items[index];
              final id = parseInt(o['id']);
              return ListTile(
                title: Text('Order #${o['number'] ?? id}'),
                subtitle: Text(o['status']?.toString() ?? ''),
                onTap: () => context.push('/orders/$id'),
              );
            },
          );
        },
      ),
    );
  }
}
