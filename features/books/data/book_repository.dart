import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/books/domain/book_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BookRepository(dio);
});

class BookStats {
  const BookStats({
    this.totalTitles = 0,
    this.totalQuantity = 0,
    this.totalInventoryValue = 0.0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
  });

  final int totalTitles;
  final int totalQuantity;
  final double totalInventoryValue;
  final int lowStockCount;
  final int outOfStockCount;

  factory BookStats.fromJson(Map<String, dynamic> json) {
    return BookStats(
      totalTitles: (json['totalTitles'] ?? 0) as int,
      totalQuantity: (json['totalQuantity'] ?? 0) as int,
      totalInventoryValue: ((json['totalInventoryValue'] ?? 0) as num).toDouble(),
      lowStockCount: (json['lowStockCount'] ?? 0) as int,
      outOfStockCount: (json['outOfStockCount'] ?? 0) as int,
    );
  }
}

class BookFetchResult {
  const BookFetchResult({
    required this.books,
    required this.stats,
  });

  final List<BookModel> books;
  final BookStats stats;
}

class BookRepository {
  BookRepository(this._dio);

  final Dio _dio;

  Future<BookFetchResult> getBooks({
    String? search,
    String? grade,
    String? subject,
    String? status,
    String? instituteId,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (grade != null && grade.isNotEmpty && grade != 'All') query['grade'] = grade;
    if (subject != null && subject.isNotEmpty && subject != 'All') query['subject'] = subject;
    if (status != null && status.isNotEmpty && status != 'All') query['status'] = status;
    if (instituteId != null && instituteId.isNotEmpty) query['instituteId'] = instituteId;

    final response = await _dio.get('/books', queryParameters: query);
    final data = response.data as Map<String, dynamic>;
    final rawBooks = (data['books'] as List?) ?? [];
    final books = rawBooks.map((e) => BookModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    final stats = data['stats'] != null
        ? BookStats.fromJson(Map<String, dynamic>.from(data['stats'] as Map))
        : const BookStats();

    return BookFetchResult(books: books, stats: stats);
  }

  Future<BookModel> createBook(Map<String, dynamic> data) async {
    final response = await _dio.post('/books', data: data);
    final resData = response.data as Map<String, dynamic>;
    return BookModel.fromJson(Map<String, dynamic>.from(resData['book'] as Map));
  }

  Future<BookModel> updateBook(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/books/$id', data: data);
    final resData = response.data as Map<String, dynamic>;
    return BookModel.fromJson(Map<String, dynamic>.from(resData['book'] as Map));
  }

  Future<void> deleteBook(String id) async {
    await _dio.delete('/books/$id');
  }

  Future<int> bulkImport(List<Map<String, dynamic>> books, {String? instituteId}) async {
    final response = await _dio.post('/books/bulk', data: {
      'books': books,
      ...?instituteId == null ? null : {'instituteId': instituteId},
    });
    final resData = response.data as Map<String, dynamic>;
    return (resData['importedCount'] ?? 0) as int;
  }
}
