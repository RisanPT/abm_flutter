/// A single page of a server-paginated list, plus the totals needed to drive
/// infinite scroll and "showing X of N" counters.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
    this.totalPages = 1,
  });

  final List<T> items;
  final int total;
  final int page;
  final bool hasMore;
  final int totalPages;

  /// Parse the backend's `{ data, total, page, totalPages, hasMore }` envelope.
  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final list = (json['data'] as List<dynamic>? ?? const [])
        .map((e) => fromItem(e as Map<String, dynamic>))
        .toList();
    return PagedResult<T>(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  static const empty = PagedResult(items: [], total: 0, page: 1, hasMore: false, totalPages: 1);
}
