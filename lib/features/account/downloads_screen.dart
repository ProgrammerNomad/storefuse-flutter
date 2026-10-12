import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_helpers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../auth/auth_repository.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  late Future<List<JsonMap>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(authRepositoryProvider).downloads();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Downloads',
      body: FutureBuilder<List<JsonMap>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No downloads available.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final d = items[index];
              return ListTile(
                title: Text(d['name']?.toString() ?? 'Download'),
                subtitle: Text(d['download_url']?.toString() ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
