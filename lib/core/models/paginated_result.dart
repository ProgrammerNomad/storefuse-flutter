import 'json_helpers.dart';

class PaginatedResult<T> {
  const PaginatedResult({required this.items, required this.meta});

  final List<T> items;
  final ListMeta meta;

  factory PaginatedResult.fromJsonMap(
    JsonMap data, {
    required List<T> Function(dynamic items) parseItems,
  }) {
    return PaginatedResult<T>(
      items: parseItems(data['items']),
      meta: ListMeta.fromPageData(data),
    );
  }

  static PaginatedResult<JsonMap> jsonMaps(JsonMap data) {
    return PaginatedResult<JsonMap>(
      items: asJsonList(data['items']),
      meta: ListMeta.fromPageData(data),
    );
  }
}
