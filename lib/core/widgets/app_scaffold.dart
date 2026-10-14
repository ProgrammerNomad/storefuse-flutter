import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/json_helpers.dart';
import '../routing/store_href.dart';
import '../../features/bootstrap/store_branding.dart';
import '../../features/bootstrap/bootstrap_provider.dart';
import '../../features/cart/cart_provider.dart';
import '../../features/catalog/storefront_providers.dart';
import 'store_logo.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = false,
    this.currentNavIndex = 0,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final int currentNavIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final onMainTab = {
      '/home',
      '/products',
      '/search',
      '/cart',
      '/account',
    }.contains(GoRouterState.of(context).uri.path);
    final logoUrl = ref.watch(storeLogoUrlProvider);
    final navAsync = ref.watch(navigationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: StoreLogo(
                  logoUrl: logoUrl,
                  height: 28,
                  fallback: Text(title),
                ),
              )
            else
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          ...?actions,
          if (!onMainTab && modules['cart'] != false)
            IconButton(
              tooltip: 'Cart',
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              onPressed: () => context.push('/cart'),
            ),
          if (!onMainTab && modules['account'] != false)
            IconButton(
              tooltip: 'Account',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/account'),
            ),
        ],
      ),
      drawer: _AppDrawer(title: title, logoUrl: logoUrl, navAsync: navAsync),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? _StoreBottomNav(
              selectedIndex: currentNavIndex,
              currentPath: GoRouterState.of(context).uri.path,
            )
          : null,
    );
  }
}

class _StoreBottomNav extends ConsumerWidget {
  const _StoreBottomNav({
    required this.selectedIndex,
    required this.currentPath,
  });

  final int selectedIndex;
  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final cartCount = ref.watch(cartCountProvider);
    final routes = <String>[
      '/home',
      if (modules['products'] != false) '/products',
      if (modules['cart'] != false) '/cart',
      if (modules['account'] != false) '/account',
    ];
    if (routes.length < 2) return const SizedBox.shrink();

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        label: 'Home',
      ),
      if (modules['products'] != false)
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          label: 'Shop',
        ),
      if (modules['cart'] != false)
        NavigationDestination(
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          label: 'Cart',
        ),
      if (modules['account'] != false)
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Account',
        ),
    ];

    var navIndex = routes.indexOf(currentPath);
    if (navIndex < 0) navIndex = selectedIndex.clamp(0, routes.length - 1);

    return NavigationBar(
      selectedIndex: navIndex,
      onDestinationSelected: (i) => context.go(routes[i]),
      destinations: destinations,
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({
    required this.title,
    required this.logoUrl,
    required this.navAsync,
  });

  final String title;
  final String? logoUrl;
  final AsyncValue<JsonMap> navAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final mainItems = navAsync.valueOrNull?['main'];
    final dynamicItems = mainItems is List && mainItems.isNotEmpty
        ? asJsonList(mainItems)
        : _defaultNavItems();

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StoreLogo(
                  logoUrl: logoUrl,
                  height: 40,
                  fallback: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (ref.watch(storeTaglineProvider) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      ref.watch(storeTaglineProvider)!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          for (final item in dynamicItems)
            if (_moduleAvailable(item['href']?.toString() ?? '', modules))
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(item['label']?.toString() ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  final route = storeHrefToRoute(
                    item['href']?.toString() ?? '',
                  );
                  if (route != null) {
                    context.push(route);
                  }
                },
              ),
          if (modules['orders'] != false) const Divider(),
          if (modules['orders'] != false)
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                context.push('/orders');
              },
            ),
        ],
      ),
    );
  }

  bool _moduleAvailable(String href, Map<String, dynamic> modules) {
    final route = storeHrefToRoute(href);
    if (route == null) return false;
    final segment = Uri.parse(route).pathSegments.firstOrNull;
    return modules[{'categories': 'products', 'home': 'homepage'}[segment] ??
            segment] !=
        false;
  }

  List<JsonMap> _defaultNavItems() {
    return [
      {'label': 'Home', 'href': '/home'},
      {'label': 'Products', 'href': '/products'},
      {'label': 'Categories', 'href': '/categories'},
      {'label': 'Search', 'href': '/search'},
    ];
  }
}
