import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../core/widgets/order_status_badge.dart';
import '../auth/auth_session_provider.dart';
import 'orders_repository.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _listKey = GlobalKey<PaginatedListViewState>();

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
      body: RefreshIndicator(
        onRefresh: () async => _listKey.currentState?.refresh(),
        child: PaginatedListView(
          key: _listKey,
          physics: const AlwaysScrollableScrollPhysics(),
          emptyTitle: 'No orders yet',
          loadPage: (page) =>
              ref.read(ordersRepositoryProvider).listPage(page: page),
          itemBuilder: (context, o, _) {
            final id = parseInt(o['id']);
            final date = o['date_created']?.toString();
            String? formattedDate;
            if (date != null) {
              final parsed = DateTime.tryParse(date);
              if (parsed != null) {
                formattedDate = DateFormat.yMMMd().format(parsed);
              }
            }
            return ListTile(
              title: Text('Order #${o['number'] ?? id}'),
              subtitle: Text(
                [
                  ?formattedDate,
                  asJsonMap(o['total'])?['formatted']?.toString(),
                ].whereType<String>().join(' · '),
              ),
              trailing: OrderStatusBadge(status: o['status']?.toString() ?? ''),
              onTap: () => context.push('/orders/$id'),
            );
          },
        ),
      ),
    );
  }
}
