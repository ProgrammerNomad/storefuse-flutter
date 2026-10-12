import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_scaffold.dart';
import '../auth/auth_repository.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(authRepositoryProvider).addresses();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Addresses',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Billing', style: Theme.of(context).textTheme.titleMedium),
              SelectableText(const JsonEncoder.withIndent('  ').convert(data['billing'] ?? {})),
              const SizedBox(height: 16),
              Text('Shipping', style: Theme.of(context).textTheme.titleMedium),
              SelectableText(const JsonEncoder.withIndent('  ').convert(data['shipping'] ?? {})),
            ],
          );
        },
      ),
    );
  }
}
