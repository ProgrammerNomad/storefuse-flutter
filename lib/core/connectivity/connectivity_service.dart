import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOfflineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityProvider).valueOrNull;
  if (result == null || result.isEmpty) return false;
  return result.every((r) => r == ConnectivityResult.none);
});
