import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../core/widgets/error_view.dart';
import 'bootstrap_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _goHomeIfReady(BuildContext context, BootstrapState state) {
    if (!state.loading && state.error == null && !state.bridgeVersionUnsupported) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);

    ref.listen(bootstrapProvider, (prev, next) {
      next.whenData((data) => _goHomeIfReady(context, data));
    });

    final ready = bootstrap.valueOrNull;
    if (ready != null &&
        !ready.loading &&
        ready.error == null &&
        !ready.bridgeVersionUnsupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _goHomeIfReady(context, ready);
      });
    }

    return Scaffold(
      body: bootstrap.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to StoreFuse Bridge…'),
            ],
          ),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(bootstrapProvider),
        ),
        data: (data) {
          if (data.error != null) {
            return ErrorView.fromException(
              data.error!,
              onRetry: () => ref.read(bootstrapProvider.notifier).refresh(),
            );
          }
          if (data.bridgeVersionUnsupported) {
            final version = data.statusData?['version'] ?? 'unknown';
            return ErrorView(
              message:
                  'Bridge $version is below minimum ${AppEnv.minSupportedBridgeVersion}. '
                  'Update the StoreFuse Bridge plugin on WordPress.',
              onRetry: () => ref.read(bootstrapProvider.notifier).refresh(),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
