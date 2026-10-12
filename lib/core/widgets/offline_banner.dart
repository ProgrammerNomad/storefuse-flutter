import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_service.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    return Stack(
      children: [
        child,
        if (offline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('You are offline')),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
