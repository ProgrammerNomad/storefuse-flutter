import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/cart_provider.dart';
import '../features/bootstrap/app_ui_config.dart';
import '../features/bootstrap/bootstrap_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final index = navigationShell.currentIndex;
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final ui = ref.watch(appUiConfigProvider);
    const tabMap = {
      'home': 0,
      'shop': 1,
      'search': 2,
      'cart': 3,
      'account': 4,
    };
    const moduleMap = {
      'shop': 'products',
      'search': 'search',
      'cart': 'cart',
      'account': 'account',
    };
    final visible = <int>[];
    for (final tab in ui.navTabs) {
      final branchIndex = tabMap[tab];
      if (branchIndex == null) continue;
      final modKey = moduleMap[tab];
      if (modKey != null && modules[modKey] == false) continue;
      visible.add(branchIndex);
    }
    if (visible.isEmpty) visible.add(0);
    final destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        label: AppLocalizations.of(context)!.home,
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        label: AppLocalizations.of(context)!.shop,
      ),
      NavigationDestination(
        icon: Icon(Icons.search),
        label: AppLocalizations.of(context)!.search,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        label: AppLocalizations.of(context)!.cart,
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: AppLocalizations.of(context)!.account,
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: visible.length < 2
          ? null
          : NavigationBar(
              selectedIndex: visible.contains(index)
                  ? visible.indexOf(index)
                  : 0,
              onDestinationSelected: (i) {
                navigationShell.goBranch(
                  visible[i],
                  initialLocation: visible[i] == navigationShell.currentIndex,
                );
              },
              destinations: [for (final i in visible) destinations[i]],
            ),
    );
  }
}
