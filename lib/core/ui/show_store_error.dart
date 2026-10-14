import 'package:flutter/material.dart';

import '../api/api_exception.dart';

/// Back-compat alias used across feature screens.
class SnackBarHelper {
  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static void showException(BuildContext context, StoreFuseApiException error) {
    showStoreError(context, error);
  }
}

/// Centralized user-facing errors for StoreFuse API failures.
void showStoreError(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) {
  final message = error is StoreFuseApiException
      ? error.message
      : error.toString().replaceFirst('Exception: ', '');
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: onRetry == null
          ? null
          : SnackBarAction(label: 'Retry', onPressed: onRetry),
    ),
  );
}

Future<void> showStoreErrorDialog(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) async {
  final message = error is StoreFuseApiException
      ? error.message
      : error.toString().replaceFirst('Exception: ', '');
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Something went wrong'),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRetry();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
