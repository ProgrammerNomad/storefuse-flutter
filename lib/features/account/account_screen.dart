import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

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
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  await ref.read(authRepositoryProvider).logout();
                  ref.invalidate(authSessionProvider);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
