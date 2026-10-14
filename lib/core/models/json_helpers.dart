import 'package:flutter/foundation.dart';

typedef JsonMap = Map<String, dynamic>;

List<JsonMap> asJsonList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

List<String> asStringList(dynamic value) {
  if (value is! List) return const [];
  final out = <String>[];
  for (final e in value) {
    final s = e?.toString() ?? '';
    if (s.isNotEmpty) out.add(s);
  }
  return out;
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
      .replaceAllMapped(RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'), (m) {
        final value = m[1]!;
        final code = value.startsWith('x')
            ? int.tryParse(value.substring(1), radix: 16)
            : int.tryParse(value);
        return code != null && code > 0 && code <= 0x10ffff
            ? String.fromCharCode(code)
            : m[0]!;
      })
      .replaceAll('&euro;', '€')
      .replaceAll('&pound;', '£')
      .replaceAll('&yen;', '¥')
      .replaceAll('&#8377;', '₹')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&');
}

bool productInStock(JsonMap product) {
  if (product.containsKey('is_in_stock')) {
    return product['is_in_stock'] == true;
  }
  final status = product['stock_status'] as String?;
  if (status != null) {
    return status == 'instock' || status == 'onbackorder';
  }
  if (product['type']?.toString() == 'variable') {
    final variations = asJsonList(product['variations']);
    for (final v in variations) {
      if (v['purchasable'] == false) continue;
      if (productInStock(v)) return true;
    }
    if (variations.isNotEmpty) return false;
  }
  return false;
}

bool productOnSale(JsonMap product) {
  if (product['on_sale'] == true) return true;
  final regular = asJsonMap(product['regular_price'])?['raw'];
  final sale = asJsonMap(product['sale_price'])?['raw'];
  if (regular is num && sale is num && sale > 0 && sale < regular) {
    return true;
  }
  return false;
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

/// Resolves list payloads from Bridge paginated envelopes (`items`, `orders`, etc.).
List<JsonMap> listItemsFromPageData(JsonMap data) {
  for (final key in const [
    'items',
    'orders',
    'posts',
    'reviews',
    'downloads',
    'products',
  ]) {
    final list = data[key];
    if (list is List && list.isNotEmpty) {
      return asJsonList(list);
    }
  }
  return asJsonList(data['items']);
}

/// Product/search card thumbnail from common Bridge shapes.
String? productThumbnailUrl(JsonMap product) {
  final thumb = imageUrl(asJsonMap(product['thumbnail']));
  if (thumb != null) return thumb;
  final single = imageUrl(asJsonMap(product['image']));
  if (single != null) return single;
  final images = product['images'];
  if (images is List && images.isNotEmpty) {
    return imageUrl(asJsonMap(images.first));
  }
  return null;
}

bool variationAttributeValueMatches(
  String variationValue,
  String selectedLabel,
) {
  final expected = variationValue.toLowerCase();
  final selected = selectedLabel.toLowerCase();
  final slugified = selected.replaceAll(' ', '-');
  return expected.isEmpty || expected == selected || expected == slugified;
}

/// Flattens Bridge checkout `packages[].methods` into a single method list.
List<JsonMap> shippingMethodsFromCheckoutData(JsonMap data) {
  final flat = asJsonList(
    data['methods'] ?? data['shipping_methods'] ?? data['items'],
  );
  if (flat.isNotEmpty) return flat;

  final packages = data['packages'];
  if (packages is! List) return const [];

  final merged = <JsonMap>[];
  for (final pkg in packages) {
    if (pkg is! Map) continue;
    final map = Map<String, dynamic>.from(pkg);
    final index = map['index'];
    for (final method in asJsonList(map['methods'])) {
      if (index != null) {
        method['_package_index'] = index;
      }
      merged.add(method);
    }
  }
  return merged;
}

bool _variationMatchesPartialSelection({
  required JsonMap variation,
  required List<JsonMap> productAttributes,
  required Map<String, String> selectedOptions,
}) {
  final rawAttrs = variation['attributes'];
  if (rawAttrs is! Map) return false;
  final varAttrs = Map<String, dynamic>.from(rawAttrs);

  for (final entry in selectedOptions.entries) {
    if (entry.value.isEmpty) continue;
    final attr = productAttributes.where(
      (a) => a['variation'] != false && a['name']?.toString() == entry.key,
    ).firstOrNull;
    if (attr == null) continue;

    final slug = attr['slug']?.toString() ?? '';
    if (slug.isEmpty) return false;
    final key = slug.startsWith('attribute_') ? slug : 'attribute_$slug';
    final expected = varAttrs[key]?.toString() ?? '';
    if (!variationAttributeValueMatches(expected, entry.value)) {
      return false;
    }
  }
  return true;
}

/// True when [optionValue] for [attributeName] can pair with [selectedOptions].
bool variationOptionIsAvailable({
  required List<JsonMap> variations,
  required List<JsonMap> productAttributes,
  required String attributeName,
  required String optionValue,
  required Map<String, String> selectedOptions,
}) {
  if (optionValue.isEmpty) return false;
  final trial = Map<String, String>.from(selectedOptions)..[attributeName] = optionValue;

  for (final variation in variations) {
    if (variation['purchasable'] == false) continue;
    if (!productInStock(variation)) continue;
    if (_variationMatchesPartialSelection(
      variation: variation,
      productAttributes: productAttributes,
      selectedOptions: trial,
    )) {
      return true;
    }
  }
  return false;
}

/// Matches a variable product variation from WC-style attribute maps.
int? matchProductVariationId({
  required List<JsonMap> variations,
  required List<JsonMap> productAttributes,
  required Map<String, String> selectedOptions,
}) {
  if (variations.isEmpty || selectedOptions.isEmpty) return null;

  for (final v in variations) {
    final rawAttrs = v['attributes'];
    if (rawAttrs is! Map) continue;
    final varAttrs = Map<String, dynamic>.from(rawAttrs);
    var matches = true;

    for (final attr in productAttributes.where(
      (a) => a['variation'] != false,
    )) {
      final label = attr['name']?.toString() ?? '';
      final slug = attr['slug']?.toString() ?? '';
      if (label.isEmpty || slug.isEmpty) continue;

      final selected = selectedOptions[label];
      if (selected == null || selected.isEmpty) {
        matches = false;
        break;
      }

      final key = slug.startsWith('attribute_') ? slug : 'attribute_$slug';
      final expected = varAttrs[key]?.toString() ?? '';
      if (!variationAttributeValueMatches(expected, selected)) {
        matches = false;
        break;
      }
    }

    if (matches) return parseInt(v['id']);
  }
  return null;
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
      items: listItemsFromPageData(data),
      meta: ListMeta.fromPageData(data),
    );
  }
}
