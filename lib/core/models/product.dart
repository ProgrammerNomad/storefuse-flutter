import 'json_helpers.dart';

class Product {
  const Product({
    required this.id,
    required this.slug,
    required this.name,
    this.type,
    this.description,
    this.descriptionHtml,
    this.price,
    this.stockStatus,
    this.images = const [],
    this.attributes = const [],
    this.variations = const [],
  });

  final int id;
  final String slug;
  final String name;
  final String? type;
  final String? description;
  final String? descriptionHtml;
  final JsonMap? price;
  final String? stockStatus;
  final List<JsonMap> images;
  final List<JsonMap> attributes;
  final List<JsonMap> variations;

  bool get inStock => productInStock(toJson());

  bool get isVariable => type == 'variable' && variations.isNotEmpty;

  factory Product.fromJson(JsonMap json) {
    return Product(
      id: parseInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      description: json['description']?.toString(),
      descriptionHtml: json['description']?.toString(),
      price: asJsonMap(json['price']),
      stockStatus: json['stock_status']?.toString(),
      images: asJsonList(json['images']),
      attributes: asJsonList(json['attributes']),
      variations: asJsonList(json['variations']),
    );
  }

  JsonMap toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
        if (type != null) 'type': type,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (stockStatus != null) 'stock_status': stockStatus,
        'images': images,
        'attributes': attributes,
        'variations': variations,
      };
}
