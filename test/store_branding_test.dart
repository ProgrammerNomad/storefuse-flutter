import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storefuse_app/features/bootstrap/bootstrap_provider.dart';
import 'package:storefuse_app/features/bootstrap/store_branding.dart';

void main() {
  test('storeThemeSeedProvider reads header color from settings', () async {
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith(
          () => _FakeBootstrapNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(bootstrapProvider.future);
    final seed = container.read(storeThemeSeedProvider);
    expect(seed, const Color(0xFFE85D04));
    expect(container.read(storeNameProvider), 'Demo Shop');
    expect(container.read(storeThemeProvider).useMaterial3, isTrue);
  });
}

class _FakeBootstrapNotifier extends BootstrapNotifier {
  @override
  Future<BootstrapState> build() async {
    return BootstrapState(
      loading: false,
      settingsData: {
        'site': {'name': 'Demo Shop', 'logo_url': 'https://example.com/logo.png'},
        'header': {'announcement_bar_bg_color': '#E85D04'},
      },
      modules: const {'products': true},
    );
  }
}
