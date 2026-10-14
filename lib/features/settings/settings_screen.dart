import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

import '../../core/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const version = '1.0.0+1';
    final settings = ref.watch(appSettingsProvider);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          ListTile(title: const Text('App version'), subtitle: Text(version)),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Use dark theme (overrides system when on)'),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (on) {
              ref
                  .read(appSettingsProvider.notifier)
                  .setThemeMode(on ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }
}
