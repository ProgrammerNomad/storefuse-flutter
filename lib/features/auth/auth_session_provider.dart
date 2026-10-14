import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_helpers.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/providers.dart';
import '../bootstrap/bootstrap_provider.dart';

/// Session load failed due to connectivity or server errors (not guest state).
class AuthSessionUnavailableException implements Exception {
  AuthSessionUnavailableException(this.cause);

  final StoreFuseApiException cause;

  bool get isOffline => cause.isOffline;

  String get message => cause.isOffline
      ? 'You appear to be offline. Check your connection and try again.'
      : 'We could not reach the store. Try again in a moment.';
}

final authSessionProvider = FutureProvider<JsonMap?>((ref) async {
  await ref.watch(bootstrapProvider.future);
  final client = await ref.watch(apiClientProvider.future);
  try {
    return (await client.authMe()).data;
  } on StoreFuseApiException catch (e) {
    if (e.code == 'not_authenticated') return null;
    if (e.isOffline || e.status == null || (e.status ?? 0) >= 500) {
      throw AuthSessionUnavailableException(e);
    }
    if (e.status == 401 || e.status == 403) return null;
    rethrow;
  }
});

final isLoggedInProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return session?['logged_in'] == true;
});
