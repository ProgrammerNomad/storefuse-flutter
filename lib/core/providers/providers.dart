import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../api/storefuse_client.dart';
import '../session/nonce_store.dart';

final appEnvProvider = Provider<AppEnv>((ref) {
  return AppEnv.fromDartDefines();
});

final apiClientProvider = FutureProvider<StoreFuseApiClient>((ref) async {
  final env = ref.watch(appEnvProvider);
  return StoreFuseApiClient.create(env);
});

final nonceStoreProvider = Provider<NonceStore>((ref) {
  throw UnimplementedError('Use client.nonces after bootstrap');
});
