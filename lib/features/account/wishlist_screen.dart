import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../auth/auth_repository.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  late Future<List<JsonMap>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(authRepositoryProvider).wishlist();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Wishlist',
      body: FutureBuilder<List<JsonMap>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Wishlist is empty.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final product = asJsonMap(item['product']) ?? item;
              final slug = product['slug'] as String? ?? '';
              return ListTile(
                title: Text(product['name']?.toString() ?? 'Product'),
                onTap: slug.isEmpty ? null : () => context.push('/products/$slug'),
              );
            },
          );
        },
      ),
    );
  }
}
