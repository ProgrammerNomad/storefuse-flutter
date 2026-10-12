import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/api/api_exception.dart';
import 'package:storefuse_app/core/api/envelope.dart';

void main() {
  group('EnvelopeParser', () {
    test('parseSuccess returns data', () {
      final result = EnvelopeParser.parseSuccess<Map<String, dynamic>>(
        {
          'schema': 'storefuse.status.v1',
          'api_version': '1.0.2',
          'data': {'status': 'ok'},
        },
        (d) => d,
      );
      expect(result.apiVersion, '1.0.2');
      expect(result.data['status'], 'ok');
    });

    test('parseError throws user-safe message', () {
      expect(
        () => EnvelopeParser.parseSuccess<Map<String, dynamic>>(
          {
            'schema': EnvelopeParser.errorSchema,
            'error': {'message': 'Not found', 'code': 'not_found', 'status': 404},
          },
          (d) => d,
        ),
        throwsA(isA<StoreFuseApiException>().having((e) => e.message, 'message', 'Not found')),
      );
    });

    test('compareSemver supports bridge gate', () {
      expect(compareSemver('1.0.2', '1.0.2'), 0);
      expect(compareSemver('1.0.3', '1.0.2'), greaterThan(0));
      expect(isBridgeVersionSupported('1.0.1'), false);
      expect(isBridgeVersionSupported('1.0.2'), true);
    });
  });
}
