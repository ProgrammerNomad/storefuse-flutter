import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../core/models/json_helpers.dart';
import '../../core/theme/store_colors.dart';
import 'app_ui_config.dart';
import 'bootstrap_provider.dart';

final appEnvFlavorProvider = Provider<AppEnv>(
  (ref) => AppEnv.fromDartDefines(),
);

final storeLogoUrlProvider = Provider<String?>((ref) {
  final settings = ref.watch(bootstrapProvider).valueOrNull?.settingsData;
  final site = asJsonMap(settings?['site']);
  final url = site?['logo_url'] as String?;
  if (url == null || url.isEmpty) return null;
  return url;
});

final storeTaglineProvider = Provider<String?>((ref) {
  final settings = ref.watch(bootstrapProvider).valueOrNull?.settingsData;
  final site = asJsonMap(settings?['site']);
  final tagline = site?['tagline'] as String?;
  if (tagline == null || tagline.isEmpty) return null;
  return tagline;
});

final storeThemeSeedProvider = Provider<Color>((ref) {
  final settings = ref.watch(bootstrapProvider).valueOrNull?.settingsData;
  final app = asJsonMap(settings?['app']);
  return parseStoreSeedColor(app?['primary_color'] as String?);
});

final storeThemeProvider = Provider<ThemeData>((ref) {
  final seed = ref.watch(storeThemeSeedProvider);
  final themeUi = ref.watch(appUiConfigProvider).theme;
  final secondary = themeUi.secondaryColor != null
      ? parseStoreSeedColor(themeUi.secondaryColor)
      : null;

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      secondary: secondary,
    ),
    fontFamily: themeUi.fontFamily != 'Default' && themeUi.fontFamily.isNotEmpty
        ? themeUi.fontFamily
        : null,
    useMaterial3: true,
  );
});

final showDevStoreInfoProvider = Provider<bool>((ref) {
  return !ref.watch(appEnvFlavorProvider).isProd;
});
