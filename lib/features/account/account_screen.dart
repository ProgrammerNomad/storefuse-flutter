import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const _appVersion = '1.0.0+1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final loggedIn = ref.watch(isLoggedInProvider);

    return AppScaffold(
      title: 'Account',
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(authSessionProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (me) {
          if (!loggedIn) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sign in to manage your account'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/auth/login'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            children: [
              ListTile(
                title: Text(me?['display_name']?.toString() ?? 'Account'),
                subtitle: Text(me?['email']?.toString() ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Orders'),
                onTap: () => context.push('/orders'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit profile'),
                onTap: () => context.push('/account/edit-profile'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password'),
                onTap: () => context.push('/account/change-password'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Addresses'),
                onTap: () => context.push('/account/addresses'),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Wishlist'),
                onTap: () => context.push('/account/wishlist'),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Downloads'),
                onTap: () => context.push('/account/downloads'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () => context.push('/settings'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Sign out?',
                    message: 'You will need to sign in again to access your account.',
                    confirmLabel: 'Sign out',
                  );
                  if (!ok) return;
                  await ref.read(authRepositoryProvider).logout();
                  ref.invalidate(authSessionProvider);
                },
              ),
              const Divider(),
              ListTile(
                title: Text('Version $_appVersion', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          );
        },
      ),
    );
  }
}
