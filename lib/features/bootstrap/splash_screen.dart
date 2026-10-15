import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/store_logo.dart';
import '../../core/widgets/storefuse_brand.dart';
import 'bootstrap_provider.dart';
import 'store_branding.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _slowTimer;
  var _showSlowMessage = false;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showSlowMessage = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  void _goHomeIfReady(BuildContext context, BootstrapState state) {
    if (!state.loading &&
        state.error == null &&
        !state.bridgeVersionUnsupported) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);
    final env = ref.watch(appEnvProvider);
    final storeName = ref.watch(storeNameProvider);
    final logoUrl = ref.watch(storeLogoUrlProvider);
    final tagline = ref.watch(storeTaglineProvider);

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
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StoreLogo(
                logoUrl: logoUrl,
                height: 64,
                fallback: StoreFuseBrandLockup(
                  name: storeName,
                  markSize: 64,
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (tagline != null) ...[
                const SizedBox(height: 8),
                Text(tagline, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                _showSlowMessage
                    ? 'Taking too long?'
                    : 'Connecting to your store…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_showSlowMessage) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(bootstrapProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
              if (!env.isProd) ...[
                const SizedBox(height: 16),
                Text(
                  env.bridgeBaseUrl,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
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
          return Center(
            child: StoreLogo(
              logoUrl: logoUrl,
              height: 64,
              fallback: StoreFuseBrandLockup(
                name: storeName,
                markSize: 64,
                textStyle: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          );
        },
      ),
    );
  }
}
