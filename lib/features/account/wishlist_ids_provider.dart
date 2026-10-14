import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../auth/auth_session_provider.dart';
import '../../core/models/json_helpers.dart';

final wishlistIdsProvider =
    AsyncNotifierProvider<WishlistIdsNotifier, Set<int>>(
      WishlistIdsNotifier.new,
    );

class WishlistIdsNotifier extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    ref.watch(isLoggedInProvider);
    if (!ref.read(isLoggedInProvider)) {
      return {};
    }
    return _load();
  }

  Future<Set<int>> _load() async {
    final items = await ref.read(authRepositoryProvider).wishlist();
    return items
        .map((e) => parseInt(e['id'] ?? e['product_id']))
        .where((id) => id > 0)
        .toSet();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> add(int productId) async {
    await ref.read(authRepositoryProvider).wishlistAdd(productId);
    final next = {...?state.valueOrNull, productId};
    state = AsyncData(next);
  }

  Future<void> remove(int productId) async {
    await ref.read(authRepositoryProvider).wishlistRemove(productId);
    final next = {...?state.valueOrNull}..remove(productId);
    state = AsyncData(next);
  }

  bool contains(int productId) =>
      state.valueOrNull?.contains(productId) ?? false;
}
