import 'api_exception.dart';

class EnvelopeResult<T> {
  EnvelopeResult({
    required this.schema,
    required this.apiVersion,
    required this.data,
  });

  final String schema;
  final String apiVersion;
  final T data;
}

/// Parses StoreFuse Bridge JSON envelopes (success and error).
class EnvelopeParser {
  static const errorSchema = 'storefuse.error.v1';

  static EnvelopeResult<T> parseSuccess<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> data) mapData,
  ) {
    if (json.containsKey('error')) {
      throw parseError(json);
    }
    final schema = json['schema'] as String? ?? '';
    final apiVersion = json['api_version'] as String? ?? '';
    final dataRaw = json['data'];
    if (dataRaw is! Map<String, dynamic>) {
      throw StoreFuseApiException(message: 'Unexpected response shape.');
    }
    return EnvelopeResult(
      schema: schema,
      apiVersion: apiVersion,
      data: mapData(dataRaw),
    );
  }

  static EnvelopeResult<T> parseSuccessDynamic<T>(
    Map<String, dynamic> json,
    T Function(dynamic data) mapData,
  ) {
    if (json.containsKey('error')) {
      throw parseError(json);
    }
    final schema = json['schema'] as String? ?? '';
    final apiVersion = json['api_version'] as String? ?? '';
    return EnvelopeResult(
      schema: schema,
      apiVersion: apiVersion,
      data: mapData(json['data']),
    );
  }

  static StoreFuseApiException parseError(Map<String, dynamic> json) {
    final err = json['error'];
    if (err is Map<String, dynamic>) {
      return StoreFuseApiException(
        message: err['message'] as String? ?? 'Something went wrong.',
        code: err['code'] as String?,
        status: err['status'] is int ? err['status'] as int : null,
        schema: json['schema'] as String?,
      );
    }
    return StoreFuseApiException(message: 'Something went wrong.');
  }

  static StoreFuseApiException parseHttpBody(dynamic body, int? statusCode) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('error')) {
        return parseError(body);
      }
    }
    return StoreFuseApiException(
      message: 'Request failed (${statusCode ?? 'unknown'}).',
      status: statusCode,
    );
  }
}

int compareSemver(String a, String b) {
  final pa = a.split('.').map(int.tryParse).toList();
  final pb = b.split('.').map(int.tryParse).toList();
  for (var i = 0; i < 3; i++) {
    final va = i < pa.length ? (pa[i] ?? 0) : 0;
    final vb = i < pb.length ? (pb[i] ?? 0) : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

bool isBridgeVersionSupported(String bridgeVersion) {
  return compareSemver(bridgeVersion, AppEnvMinBridge.min) >= 0;
}

/// Avoid importing [AppEnv] in tests that only need version compare.
class AppEnvMinBridge {
  static const min = '1.0.2';
}
