import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_view.dart';
import 'catalog_repository.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  late Future<List<JsonMap>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(catalogRepositoryProvider).categories();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Categories',
      body: FutureBuilder<List<JsonMap>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _future = ref.read(catalogRepositoryProvider).categories();
              }),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No categories.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final c = items[index];
              final slug = c['slug'] as String? ?? '';
              return ListTile(
                title: Text(c['name']?.toString() ?? slug),
                trailing: const Icon(Icons.chevron_right),
                onTap: slug.isEmpty
                    ? null
                    : () => context.push('/categories/$slug'),
              );
            },
          );
        },
      ),
    );
  }
}
