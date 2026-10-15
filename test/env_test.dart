import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/config/env.dart';

void main() {
  group('normalizeBridgeBaseUrl', () {
    const ns = 'storefuse/v1';

    test('leaves site root unchanged', () {
      expect(
        AppEnv.normalizeBridgeBaseUrl('https://shop.example.com', ns),
        'https://shop.example.com',
      );
    });

    test('strips pasted REST root', () {
      expect(
        AppEnv.normalizeBridgeBaseUrl(
          'https://shop.example.com/wp-json/storefuse/v1',
          ns,
        ),
        'https://shop.example.com',
      );
    });

    test('strips trailing slashes on site root and REST root', () {
      expect(
        AppEnv.normalizeBridgeBaseUrl('https://shop.example.com/', ns),
        'https://shop.example.com',
      );
      expect(
        AppEnv.normalizeBridgeBaseUrl(
          'https://shop.example.com/wp-json/storefuse/v1/',
          ns,
        ),
        'https://shop.example.com',
      );
    });

    test('pasted REST root yields same api path as site root', () {
      const site = 'https://shop.example.com';
      const pasted = 'https://shop.example.com/wp-json/storefuse/v1';
      final fromSite =
          AppEnv.normalizeBridgeBaseUrl(site, ns);
      final fromPasted =
          AppEnv.normalizeBridgeBaseUrl(pasted, ns);
      expect(fromSite, fromPasted);
      expect('$fromSite/wp-json/$ns', 'https://shop.example.com/wp-json/storefuse/v1');
    });
  });
}
