import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/models/json_helpers.dart';
import 'package:storefuse_app/core/models/paginated_result.dart';

void main() {
  test('PaginatedResult parses items and total_pages', () {
    final result = PaginatedResult.jsonMaps({
      'items': [
        {'id': 1, 'slug': 'a'},
        {'id': 2, 'slug': 'b'},
      ],
      'page': 2,
      'per_page': 10,
      'total': 25,
      'total_pages': 3,
    });

    expect(result.items.length, 2);
    expect(result.meta.page, 2);
    expect(result.meta.totalPages, 3);
    expect(result.meta.total, 25);
  });

  test('PaginatedResult resolves orders and posts resource keys', () {
    final orders = PaginatedResult.jsonMaps({
      'orders': [
        {'id': 10},
      ],
      'meta': {'total': 1, 'page': 1, 'per_page': 10, 'total_pages': 1},
    });
    expect(orders.items.length, 1);

    final posts = PaginatedResult.jsonMaps({
      'posts': [
        {'slug': 'hello'},
      ],
      'page': 1,
      'total': 1,
      'total_pages': 1,
    });
    expect(posts.items.first['slug'], 'hello');
  });

  test('ListMeta defaults when fields missing', () {
    final meta = ListMeta.fromJson({});
    expect(meta.page, 1);
    expect(meta.totalPages, 0);
  });
}
