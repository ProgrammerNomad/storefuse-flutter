import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/storefuse_brand.dart';
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
    final social =
        asJsonMap(
          ref
              .watch(bootstrapProvider)
              .valueOrNull
              ?.settingsData?['social_links'],
        ) ??
        {};
    final links = <MapEntry<String, dynamic>>[
      MapEntry('Privacy policy', app['privacy_url']),
      MapEntry('Terms and conditions', app['terms_url']),
      MapEntry('Contact support', app['support_url']),
      MapEntry(
        'Account deletion',
        app['deletion_url'] ?? app['account_deletion_url'],
      ),
      MapEntry('Instagram', social['instagram']),
      MapEntry('Facebook', social['facebook']),
      MapEntry('X / Twitter', social['twitter']),
      MapEntry('YouTube', social['youtube']),
      MapEntry('Pinterest', social['pinterest']),
      MapEntry('WhatsApp', social['whatsapp']),
    ];
    return AppScaffold(
      title: 'About and support',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StoreFuseBrandLockup(name: 'StoreFuse mobile', markSize: 48),
          const SizedBox(height: 16),
          for (final entry in links)
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
