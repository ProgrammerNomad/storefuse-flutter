import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/cart_provider.dart';
import '../features/bootstrap/bootstrap_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final index = navigationShell.currentIndex;
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final visible = [
      0,
      if (modules['products'] != false) 1,
      if (modules['search'] != false) 2,
      if (modules['cart'] != false) 3,
      if (modules['account'] != false) 4,
    ];
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
