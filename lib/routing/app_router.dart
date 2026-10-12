import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
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

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final env = AppEnv.fromDartDefines();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/products', builder: (_, __) => const ProductListScreen()),
      GoRoute(
        path: '/products/:slug',
        builder: (_, state) => ProductDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/product/:slug',
        redirect: (_, state) => '/products/${state.pathParameters['slug']}',
      ),
      GoRoute(path: '/categories', builder: (_, __) => const CategoryListScreen()),
      GoRoute(
        path: '/categories/:slug',
        builder: (_, state) => CategoryDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/posts', builder: (_, __) => const PostsScreen()),
      GoRoute(
        path: '/posts/:slug',
        builder: (_, state) => PostDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
        path: '/orders/confirm/:key',
        builder: (_, state) =>
            OrderConfirmationScreen(orderKey: state.pathParameters['key']!),
      ),
      GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      GoRoute(path: '/account/addresses', builder: (_, __) => const AddressesScreen()),
      GoRoute(path: '/account/wishlist', builder: (_, __) => const WishlistScreen()),
      GoRoute(path: '/account/downloads', builder: (_, __) => const DownloadsScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
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
      if (uri.scheme == env.deepLinkScheme && uri.host == 'reset') {
        return Uri(
          path: '/auth/reset-password',
          queryParameters: uri.queryParameters,
        ).toString();
      }
      return null;
    },
  );
});
