import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../core/models/json_helpers.dart';
import '../../core/theme/store_colors.dart';
import 'bootstrap_provider.dart';

final appEnvFlavorProvider = Provider<AppEnv>((ref) => AppEnv.fromDartDefines());

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
  final header = asJsonMap(settings?['header']);
  return parseStoreSeedColor(header?['announcement_bar_bg_color'] as String?);
});

final storeThemeProvider = Provider<ThemeData>((ref) {
  final seed = ref.watch(storeThemeSeedProvider);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    useMaterial3: true,
  );
});

final showDevStoreInfoProvider = Provider<bool>((ref) {
  return !ref.watch(appEnvFlavorProvider).isProd;
});
