import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';

class StoreFuseApp extends ConsumerStatefulWidget {
  const StoreFuseApp({super.key});

  @override
  ConsumerState<StoreFuseApp> createState() => _StoreFuseAppState();
}

class _StoreFuseAppState extends ConsumerState<StoreFuseApp> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
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
    return MaterialApp.router(
      title: 'StoreFuse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE85D04)),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: [
            if (_offline)
              MaterialBanner(
                content: const Text('You are offline. Some actions may fail.'),
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
