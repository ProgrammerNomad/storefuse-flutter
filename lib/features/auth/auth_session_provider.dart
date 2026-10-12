import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../bootstrap/bootstrap_provider.dart';

final authSessionProvider = FutureProvider<JsonMap?>((ref) async {
  ref.watch(bootstrapProvider);
  final client = await ref.watch(apiClientProvider.future);
  try {
    return (await client.authMe()).data;
  } catch (_) {
    return null;
  }
});

final isLoggedInProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return session?['logged_in'] == true;
});
