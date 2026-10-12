import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../bootstrap/bootstrap_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider).valueOrNull;
    final settings = bootstrap?.settingsData;
    final site = asJsonMap(settings?['site']);
    final store = asJsonMap(settings?['store']);
    final name = site?['name'] as String? ?? ref.watch(storeNameProvider);

    return AppScaffold(
      title: name ?? 'StoreFuse',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            store?['currency'] != null
                ? 'Currency: ${store!['currency']}'
                : 'Browse products from your WooCommerce store.',
          ),
          if (bootstrap?.statusData != null) ...[
            const SizedBox(height: 16),
            Text(
              'Bridge ${bootstrap!.statusData!['version']} · '
              'Checkout: ${bootstrap.headlessCheckout ? 'headless' : 'redirect'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => context.push('/products'),
                child: const Text('Shop products'),
              ),
              OutlinedButton(
                onPressed: () => context.push('/categories'),
                child: const Text('Categories'),
              ),
              OutlinedButton(
                onPressed: () => context.push('/search'),
                child: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
