import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  AppSettings copyWith({ThemeMode? themeMode}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode);
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class SettingsState {
  const SettingsState({this.darkMode = false});

  final bool darkMode;
}

final settingsProvider = Provider<SettingsState>((ref) {
  final mode = ref.watch(appSettingsProvider).themeMode;
  return SettingsState(darkMode: mode == ThemeMode.dark);
});
