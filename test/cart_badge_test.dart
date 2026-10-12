import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storefuse_app/features/bootstrap/bootstrap_provider.dart';
import 'package:storefuse_app/features/cart/cart_provider.dart';

void main() {
  test('cartCountProvider reads item_count from bootstrap cart', () async {
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith(
          () => _StaticBootstrapNotifier(
            BootstrapState(
              loading: false,
              cartData: {'item_count': 3},
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(bootstrapProvider.future);
    expect(container.read(cartCountProvider), 3);
  });
}

class _StaticBootstrapNotifier extends BootstrapNotifier {
  _StaticBootstrapNotifier(this._state);

  final BootstrapState _state;

  @override
  Future<BootstrapState> build() async => _state;
}
