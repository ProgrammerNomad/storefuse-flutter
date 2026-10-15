import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import '../bootstrap/app_ui_config.dart';

import '../../core/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const version = '1.0.0+1';
    final settings = ref.watch(appSettingsProvider);
    final configuredThemeMode = ref.watch(appUiConfigProvider).theme.themeMode;
    final themeIsManagedByStore =
        configuredThemeMode == 'light' || configuredThemeMode == 'dark';

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          ListTile(title: const Text('App version'), subtitle: Text(version)),
          if (themeIsManagedByStore)
            ListTile(
              title: const Text('Appearance'),
              subtitle: Text(
                configuredThemeMode == 'dark'
                    ? 'Dark theme is set by this store.'
                    : 'Light theme is set by this store.',
              ),
            )
          else
            SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Use dark theme on this device.'),
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
