class StoreFuseApiException implements Exception {
  StoreFuseApiException({
    required this.message,
    this.code,
    this.status,
    this.schema,
    this.isOffline = false,
  });

  final String message;
  final String? code;
  final int? status;
  final String? schema;
  final bool isOffline;

  @override
  String toString() => message;
}
