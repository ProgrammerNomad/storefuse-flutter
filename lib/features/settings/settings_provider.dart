import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  AppSettings build() {
    _restore();
    return const AppSettings();
  }

  bool _changed = false;
  Future<void> _restore() async {
    try {
      final value = await const FlutterSecureStorage().read(
        key: 'storefuse.theme',
      );
      if (!_changed && value != null) {
        state = state.copyWith(
          themeMode: ThemeMode.values.firstWhere(
            (m) => m.name == value,
            orElse: () => ThemeMode.system,
          ),
        );
      }
    } catch (_) {
      /* System theme remains usable if storage is unavailable. */
    }
  }

  void setThemeMode(ThemeMode mode) {
    _changed = true;
    state = state.copyWith(themeMode: mode);
    const FlutterSecureStorage()
        .write(key: 'storefuse.theme', value: mode.name)
        .catchError((Object _) {
          /* The current in-memory choice remains usable. */
        });
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
