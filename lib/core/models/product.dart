import 'json_helpers.dart';

class Product {
  const Product({
    required this.id,
    required this.slug,
    required this.name,
    this.type,
    this.permalink,
    this.regularPrice,
    this.salePrice,
    this.onSale = false,
    this.purchasable = true,
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
  final String? permalink;
  final JsonMap? regularPrice;
  final JsonMap? salePrice;
  final bool onSale;
  final bool purchasable;
  final String? description;
  final String? descriptionHtml;
  final JsonMap? price;
  final String? stockStatus;
  final List<JsonMap> images;
  final List<JsonMap> attributes;
  final List<JsonMap> variations;

  bool get inStock => productInStock(toJson());

  bool get isVariable => type == 'variable';

  factory Product.fromJson(JsonMap json) {
    return Product(
      id: parseInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      permalink: json['permalink']?.toString(),
      regularPrice: asJsonMap(json['regular_price']),
      salePrice: asJsonMap(json['sale_price']),
      onSale: json['on_sale'] == true,
      purchasable: json['purchasable'] != false,
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
    'regular_price': regularPrice,
    'sale_price': salePrice,
    'on_sale': onSale,
    'purchasable': purchasable,
    if (type != null) 'type': type,
    if (description != null) 'description': description,
    if (price != null) 'price': price,
    if (stockStatus != null) 'stock_status': stockStatus,
    'images': images,
    'attributes': attributes,
    'variations': variations,
  };
}
