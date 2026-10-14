import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/app_scaffold.dart';
import '../bootstrap/bootstrap_provider.dart';
import '../../core/models/json_helpers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app =
        asJsonMap(
          ref.watch(bootstrapProvider).valueOrNull?.settingsData?['app'],
        ) ??
        {};
    return AppScaffold(
      title: 'About and support',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('StoreFuse mobile client'),
          const SizedBox(height: 16),
          for (final entry in {
            'Privacy policy': app['privacy_url'],
            'Terms and conditions': app['terms_url'],
            'Contact support': app['support_url'],
            'Account deletion': app['account_deletion_url'],
          }.entries)
            if (Uri.tryParse(entry.value?.toString() ?? '') case final Uri url
                when url.scheme == 'https' || url.scheme == 'http')
              ListTile(
                title: Text(entry.key),
                trailing: const Icon(Icons.open_in_new),
                onTap: () =>
                    launchUrl(url, mode: LaunchMode.externalApplication),
              ),
        ],
      ),
    );
  }
}
