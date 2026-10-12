import 'package:flutter/foundation.dart';

typedef JsonMap = Map<String, dynamic>;

List<JsonMap> asJsonList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

JsonMap? asJsonMap(dynamic value) {
  if (value is JsonMap) return value;
  return null;
}

String priceFormatted(JsonMap? price) {
  if (price == null) return '';
  final formatted = price['formatted'];
  if (formatted is String) {
    return _decodeHtmlEntities(formatted);
  }
  final raw = price['raw'];
  if (raw is num) return raw.toString();
  return '';
}

String _decodeHtmlEntities(String input) {
  return input
      .replaceAll('&#8377;', '₹')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&');
}

bool productInStock(JsonMap product) {
  final status = product['stock_status'] as String?;
  if (status != null) {
    return status == 'instock' || status == 'onbackorder';
  }
  return product['is_in_stock'] == true;
}

int parseInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String? imageUrl(JsonMap? image) {
  if (image == null) return null;
  return image['src'] as String? ?? image['url'] as String?;
}

@immutable
class ListMeta {
  const ListMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  factory ListMeta.fromJson(JsonMap? meta) {
    if (meta == null) {
      return const ListMeta(page: 1, perPage: 20, total: 0, totalPages: 0);
    }
    return ListMeta(
      page: parseInt(meta['page'], fallback: 1),
      perPage: parseInt(meta['per_page'], fallback: 20),
      total: parseInt(meta['total']),
      totalPages: parseInt(meta['total_pages']),
    );
  }

  factory ListMeta.fromPageData(JsonMap data) {
    final nested = asJsonMap(data['meta']);
    if (nested != null &&
        (nested.containsKey('page') ||
            nested.containsKey('total') ||
            nested.containsKey('total_pages'))) {
      return ListMeta.fromJson(nested);
    }
    return ListMeta.fromJson(data);
  }
}

@immutable
class PaginatedListResult {
  const PaginatedListResult({required this.items, required this.meta});

  final List<JsonMap> items;
  final ListMeta meta;

  factory PaginatedListResult.fromJson(JsonMap data) {
    return PaginatedListResult(
      items: asJsonList(data['items']),
      meta: ListMeta.fromPageData(data),
    );
  }
}
