import '../core/utils/json_utils.dart';

class Pagination {
  const Pagination({
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    final perPage = Json.integer(json['per_page'] ?? json['perPage'], 20);
    final total = Json.integer(json['total']);
    return Pagination(
      page: Json.integer(json['current_page'] ?? json['page'], 1),
      perPage: perPage,
      total: total,
      lastPage: Json.integer(
        json['last_page'] ?? json['lastPage'],
        perPage == 0 ? 1 : (total / perPage).ceil(),
      ),
    );
  }

  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasMore => page < lastPage;

  Map<String, dynamic> toJson() => {
    'current_page': page,
    'per_page': perPage,
    'total': total,
    'last_page': lastPage,
  };
}

/// A page of results plus paging metadata.
class PaginatedList<T> {
  const PaginatedList({required this.items, required this.pagination});

  /// Parses `{ "items": [...], "pagination": {...} }`. A bare list is
  /// treated as a single complete page.
  factory PaginatedList.fromData(
    Object? data,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (data is List) {
      final items = Json.list(data, parse);
      return PaginatedList(
        items: items,
        pagination: Pagination(page: 1, perPage: items.length, total: items.length, lastPage: 1),
      );
    }
    final json = Json.map(data);
    final items = Json.list(json['items'], parse);
    final meta = Json.mapOrNull(json['pagination']);
    return PaginatedList(
      items: items,
      pagination: meta == null
          ? Pagination(page: 1, perPage: items.length, total: items.length, lastPage: 1)
          : Pagination.fromJson(meta),
    );
  }

  final List<T> items;
  final Pagination pagination;

  bool get hasMore => pagination.hasMore;
}
