import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../features/bootstrap/bootstrap_provider.dart';
import '../features/account/account_screen.dart';
import '../features/account/addresses_screen.dart';
import '../features/account/downloads_screen.dart';
import '../features/account/wishlist_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/bootstrap/splash_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/catalog/category_detail_screen.dart';
import '../features/catalog/category_list_screen.dart';
import '../features/catalog/home_screen.dart';
import '../features/catalog/product_detail_screen.dart';
import '../features/catalog/product_list_screen.dart';
import '../features/search/posts_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/order_confirmation_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/orders/order_list_screen.dart';
import '../features/search/search_screen.dart';
import '../features/account/change_password_screen.dart';
import '../features/account/edit_profile_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import 'main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shopNavKey = GlobalKey<NavigatorState>(debugLabel: 'shop');
final _searchNavKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _cartNavKey = GlobalKey<NavigatorState>(debugLabel: 'cart');
final _accountNavKey = GlobalKey<NavigatorState>(debugLabel: 'account');

final appRouterProvider = Provider<GoRouter>((ref) {
  final env = AppEnv.fromDartDefines();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/unavailable',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Unavailable')),
          body: Center(
            child: FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('This feature is unavailable. Return home'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'posts',
                    builder: (_, _) => const PostsScreen(),
                    routes: [
                      GoRoute(
                        path: ':slug',
                        builder: (_, state) => PostDetailScreen(
                          slug: state.pathParameters['slug']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shopNavKey,
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, _) => const ProductListScreen(),
                routes: [
                  GoRoute(
                    path: ':slug',
                    builder: (_, state) => ProductDetailScreen(
                      slug: state.pathParameters['slug']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/categories',
                builder: (_, _) => const CategoryListScreen(),
              ),
              GoRoute(
                path: '/categories/:slug',
                builder: (_, state) =>
                    CategoryDetailScreen(slug: state.pathParameters['slug']!),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavKey,
            routes: [
              GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _cartNavKey,
            routes: [
              GoRoute(
                path: '/cart',
                builder: (_, _) => const CartScreen(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    builder: (_, _) => const CheckoutScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _accountNavKey,
            routes: [
              GoRoute(
                path: '/account',
                builder: (_, _) => const AccountScreen(),
                routes: [
                  GoRoute(
                    path: 'edit-profile',
                    builder: (_, _) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (_, _) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'addresses',
                    builder: (_, _) => const AddressesScreen(),
                  ),
                  GoRoute(
                    path: 'wishlist',
                    builder: (_, _) => const WishlistScreen(),
                  ),
                  GoRoute(
                    path: 'downloads',
                    builder: (_, _) => const DownloadsScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/orders',
                builder: (_, _) => const OrderListScreen(),
              ),
              GoRoute(
                path: '/orders/:id',
                builder: (_, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return OrderDetailScreen(orderId: id);
                },
              ),
              GoRoute(
                path: '/orders/confirm/:key',
                builder: (_, state) => OrderConfirmationScreen(
                  orderKey: state.pathParameters['key']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:slug',
        redirect: (_, state) => '/products/${state.pathParameters['slug']}',
      ),
      GoRoute(path: '/posts', redirect: (_, _) => '/home/posts'),
      GoRoute(
        path: '/posts/:slug',
        redirect: (_, state) => '/home/posts/${state.pathParameters['slug']}',
      ),
      GoRoute(path: '/checkout', redirect: (_, _) => '/cart/checkout'),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/settings/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/auth/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/auth/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          keyParam: state.uri.queryParameters['key'] ?? '',
          login: state.uri.queryParameters['login'] ?? '',
        ),
      ),
    ],
    redirect: (context, state) {
      final uri = state.uri;
      final modules = ref.read(bootstrapProvider).valueOrNull?.modules ?? {};
      const routeModules = {
        '/cart/checkout': 'checkout',
        '/checkout': 'checkout',
        '/account/addresses': 'addresses',
        '/account/wishlist': 'wishlist',
        '/account/downloads': 'downloads',
        '/products': 'products',
        '/categories': 'categories',
        '/search': 'search',
        '/cart': 'cart',
        '/account': 'account',
        '/orders': 'orders',
        '/home/posts': 'posts',
      };
      for (final entry in routeModules.entries) {
        if ((uri.path == entry.key || uri.path.startsWith('${entry.key}/')) &&
            modules[entry.value] == false) {
          return '/unavailable';
        }
      }
      if (uri.scheme == env.deepLinkScheme) {
        if (uri.host == 'reset') {
          return Uri(
            path: '/auth/reset-password',
            queryParameters: uri.queryParameters,
          ).toString();
        }
        if (uri.host == 'product' && uri.pathSegments.isNotEmpty) {
          return '/products/${uri.pathSegments.first}';
        }
        if (uri.host == 'products' && uri.pathSegments.isNotEmpty) {
          return '/products/${uri.pathSegments.first}';
        }
        if (uri.host == 'category' && uri.pathSegments.isNotEmpty) {
          return '/categories/${uri.pathSegments.first}';
        }
        if (uri.host == 'categories' && uri.pathSegments.isNotEmpty) {
          return '/categories/${uri.pathSegments.first}';
        }
      }
      return null;
    },
  );
});
