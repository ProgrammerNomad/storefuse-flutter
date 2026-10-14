import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_session_provider.dart';

class GuestLoginPromptBanner extends ConsumerWidget {
  const GuestLoginPromptBanner({
    super.key,
    this.title = 'Already have an account?',
    this.message = 'Sign in for faster checkout, saved addresses, and order tracking.',
    this.buttonLabel = 'Sign in',
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final String title;
  final String message;
  final String buttonLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(isLoggedInProvider);
    if (loggedIn) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withAlpha(60),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.push('/auth/login'),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
