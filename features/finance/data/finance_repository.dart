import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final madrassaFinanceRepositoryProvider = Provider<MadrassaFinanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MadrassaFinanceRepository(dio);
});

// ─── Models ──────────────────────────────────────────────────────────────────

class MadrassaExpense {
  const MadrassaExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    required this.processedBy,
    this.referenceId,
  });

  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String description;
  final String processedBy;
  final String? referenceId;

  factory MadrassaExpense.fromJson(Map<String, dynamic> json) => MadrassaExpense(
        id: json['_id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String? ?? '',
        processedBy: json['processedBy'] as String,
        referenceId: json['referenceId'] as String?,
      );
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.type,
    required this.amount,
  });

  final String id;
  final String name;
  final String description;
  final bool isSystem;
  final String type; // 'Income' or 'Expense'
  final double amount;

  factory FinanceCategory.fromJson(Map<String, dynamic> json) => FinanceCategory(
        id: json['_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        isSystem: json['isSystem'] as bool? ?? false,
        type: json['type'] as String? ?? 'Expense',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

// ─── Repository ───────────────────────────────────────────────────────────────

class MadrassaFinanceRepository {
  MadrassaFinanceRepository(this._dio);
  final Dio _dio;

  // ── Expenses ─────────────────────────────────────────────────────────────

  Future<List<MadrassaExpense>> getExpenses({String? category, String? month}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;
      if (month != null) params['month'] = month;
      final response = await _dio.get(
        '/finance',
        queryParameters: params.isEmpty ? null : params,
      );
      final data = response.data as List;
      return data.map((e) => MadrassaExpense.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    required String description,
    required String processedBy,
    DateTime? date,
  }) async {
    try {
      await _dio.post('/finance', data: {
        'category': category,
        'amount': amount,
        'description': description,
        'processedBy': processedBy,
        if (date != null) 'date': date.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  Future<void> processSalary({
    required String teacherId,
    required String month,
  }) async {
    try {
      await _dio.post('/finance/process-salary', data: {
        'teacherId': teacherId,
        'month': month,
      });
    } catch (e) {
      throw Exception('Failed to process salary: $e');
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<FinanceCategory>> getCategories({String? type}) async {
    try {
      final response = await _dio.get(
        '/finance/categories',
        queryParameters: type != null ? {'type': type} : null,
      );
      final data = response.data as List;
      return data.map((e) => FinanceCategory.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<FinanceCategory> createCategory({
    required String name,
    String description = '',
    String type = 'Expense',
    double amount = 0,
  }) async {
    try {
      final response = await _dio.post('/finance/categories', data: {
        'name': name,
        'description': description,
        'type': type,
        'amount': amount,
      });
      return FinanceCategory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<FinanceCategory> updateCategory({
    required String id,
    String? name,
    String? description,
    String? type,
    double? amount,
  }) async {
    try {
      // Use request body (PUT) instead of fragile query string concatenation
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (type != null) data['type'] = type;
      if (amount != null) data['amount'] = amount;
      final response = await _dio.put('/finance/categories/$id', data: data);
      return FinanceCategory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('/finance/categories/$id');
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // ── P&L Report ─────────────────────────────────────────────────────────────

  /// Returns combined income (from fees) and expense data for a given month.
  /// month format: "yyyy-MM"
  Future<Map<String, dynamic>> getPnlReport({required String month}) async {
    try {
      final response = await _dio.get(
        '/finance/report',
        queryParameters: {'month': month},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch finance report: $e');
    }
  }
}
