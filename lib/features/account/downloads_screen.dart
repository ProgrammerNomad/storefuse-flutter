import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/json_helpers.dart';
import '../../core/ui/show_store_error.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
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
    _reload();
  }

  void _reload() {
    _future = ref.read(authRepositoryProvider).downloads();
  }

  Future<void> _openDownload(JsonMap d) async {
    final url = d['download_url']?.toString() ?? d['url']?.toString() ?? '';
    if (url.isEmpty) {
      if (!context.mounted) return;
      SnackBarHelper.showMessage(context, 'No download URL available.');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!context.mounted) return;
      SnackBarHelper.showMessage(context, 'Invalid download URL.');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        if (!context.mounted) return;
        SnackBarHelper.showMessage(context, 'Could not open download.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Downloads',
      body: FutureBuilder<List<JsonMap>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyStateView(title: 'No downloads available');
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final d = items[index];
              final remaining = d['downloads_remaining'];
              return ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(
                  d['name']?.toString() ??
                      d['product_name']?.toString() ??
                      'Download',
                ),
                subtitle: Text(
                  [
                    if (d['file'] != null) d['file'].toString(),
                    if (remaining != null) 'Remaining: $remaining',
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openDownload(d),
              );
            },
          );
        },
      ),
    );
  }
}
