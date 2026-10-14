import 'l10n/app_localizations.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/bootstrap/bootstrap_provider.dart';
import 'features/bootstrap/store_branding.dart';
import 'features/settings/settings_provider.dart';
import 'routing/app_router.dart';

class StoreFuseApp extends ConsumerStatefulWidget {
  const StoreFuseApp({super.key});

  @override
  ConsumerState<StoreFuseApp> createState() => _StoreFuseAppState();
}

class _StoreFuseAppState extends ConsumerState<StoreFuseApp> {
  bool _offline = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _offline = offline);
    });
    Connectivity().checkConnectivity().then((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _offline = offline);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final storeName = ref.watch(storeNameProvider);
    final theme = ref.watch(storeThemeProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.colorScheme.primary,
        secondary: theme.colorScheme.secondary,
        brightness: Brightness.dark,
      ),
      fontFamily: theme.textTheme.bodyMedium?.fontFamily,
      useMaterial3: true,
    );

    return MaterialApp.router(
      title: storeName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: appSettings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: [
            if (_offline)
              MaterialBanner(
                content: Text(AppLocalizations.of(context)!.offlineMessage),
                leading: const Icon(Icons.cloud_off),
                actions: const [SizedBox.shrink()],
              ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
