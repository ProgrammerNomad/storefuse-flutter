import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/envelope.dart';
import '../../core/api/storefuse_client.dart' show StoreFuseApiClient;
import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';

class BootstrapState {
  const BootstrapState({
    this.loading = true,
    this.statusData,
    this.settingsData,
    this.cartData,
    this.error,
    this.bridgeVersionUnsupported = false,
    this.headlessCheckout = false,
    this.modules = const {},
  });

  final bool loading;
  final JsonMap? statusData;
  final JsonMap? settingsData;
  final JsonMap? cartData;
  final StoreFuseApiException? error;
  final bool bridgeVersionUnsupported;
  final bool headlessCheckout;
  final Map<String, bool> modules;

  BootstrapState copyWith({
    bool? loading,
    JsonMap? statusData,
    JsonMap? settingsData,
    JsonMap? cartData,
    StoreFuseApiException? error,
    bool? bridgeVersionUnsupported,
    bool? headlessCheckout,
    Map<String, bool>? modules,
  }) {
    return BootstrapState(
      loading: loading ?? this.loading,
      statusData: statusData ?? this.statusData,
      settingsData: settingsData ?? this.settingsData,
      cartData: cartData ?? this.cartData,
      error: error,
      bridgeVersionUnsupported: bridgeVersionUnsupported ?? this.bridgeVersionUnsupported,
      headlessCheckout: headlessCheckout ?? this.headlessCheckout,
      modules: modules ?? this.modules,
    );
  }
}

class BootstrapNotifier extends AsyncNotifier<BootstrapState> {
  StoreFuseApiClient? _client;

  StoreFuseApiClient get client {
    final c = _client;
    if (c == null) throw StateError('Client not ready');
    return c;
  }

  @override
  Future<BootstrapState> build() async {
    final client = await ref.watch(apiClientProvider.future);
    _client = client;
    return _runBootstrap(client);
  }

  Future<BootstrapState> refresh() async {
    state = const AsyncLoading();
    final client = await ref.read(apiClientProvider.future);
    _client = client;
    final result = await _runBootstrap(client);
    state = AsyncData(result);
    return result;
  }

  Future<BootstrapState> _runBootstrap(StoreFuseApiClient client) async {
    try {
      final status = await client.getStatus();
      final statusData = status.data;
      final bridgeVersion = statusData['version'] as String? ?? '';
      final unsupported = bridgeVersion.isNotEmpty &&
          !isBridgeVersionSupported(bridgeVersion);
      final features = asJsonMap(statusData['features']) ?? {};
      final headless = features['headless_checkout'] == true;
      final modulesRaw = asJsonMap(statusData['modules']) ?? {};
      final modules = modulesRaw.map((k, v) => MapEntry(k, v == true));

      if (statusData['status'] != 'ok') {
        throw StoreFuseApiException(message: 'Store is unavailable right now.');
      }

      final settingsFuture = _loadSettings(client);
      final cartFuture = _loadCart(client);
      final authFuture = client.authMe().then((_) {}, onError: (_) {});

      final settings = await settingsFuture;
      final cart = await cartFuture;
      await authFuture;

      return BootstrapState(
        loading: false,
        statusData: statusData,
        settingsData: settings,
        cartData: cart,
        bridgeVersionUnsupported: unsupported,
        headlessCheckout: headless,
        modules: modules,
      );
    } on StoreFuseApiException catch (e) {
      return BootstrapState(loading: false, error: e);
    } catch (_) {
      final env = ref.read(appEnvProvider);
      final hint = env.isProd
          ? ''
          : ' Check ${env.bridgeBaseUrl} (Android emulator: http://10.0.2.2).';
      return BootstrapState(
        loading: false,
        error: StoreFuseApiException(message: 'Could not connect to the store.$hint'),
      );
    }
  }

  Future<JsonMap?> _loadSettings(StoreFuseApiClient client) async {
    try {
      return (await client.getSettings()).data;
    } catch (_) {
      return null;
    }
  }

  Future<JsonMap?> _loadCart(StoreFuseApiClient client) async {
    try {
      return (await client.getCart()).data;
    } catch (_) {
      try {
        await client.bootstrapNonces();
        return (await client.getCart()).data;
      } catch (_) {
        return null;
      }
    }
  }
}

final bootstrapProvider =
    AsyncNotifierProvider<BootstrapNotifier, BootstrapState>(BootstrapNotifier.new);

final storeNameProvider = Provider<String>((ref) {
  final bootstrap = ref.watch(bootstrapProvider).valueOrNull;
  final settings = bootstrap?.settingsData;
  final site = asJsonMap(settings?['site']);
  return site?['name'] as String? ?? 'StoreFuse';
});

final minBridgeProvider = Provider<String>((_) => AppEnv.minSupportedBridgeVersion);
