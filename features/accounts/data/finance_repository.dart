import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AccountRepository(dio);
});

class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  Future<List<AccountSummary>> getStudentSummaries({String? instituteId}) async {
    try {
      final response = await _dio.get(
        '/accounts/students',
        queryParameters: instituteId != null ? {'instituteId': instituteId} : null,
      );
      final data = response.data as List<dynamic>;
      return data
          .map((item) => AccountSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch account summaries: $e');
    }
  }

  Future<StudentAccountDetails> getStudentAccountDetails(String studentId) async {
    try {
      final response = await _dio.get('/accounts/student/$studentId');
      return StudentAccountDetails.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch account details: $e');
    }
  }

  Future<ReceiptHistoryItem> processPayment({
    required String studentId,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/student/$studentId/pay',
        data: {'amount': amount},
      );
      final data = response.data as Map<String, dynamic>;
      return ReceiptHistoryItem(
        id: (data['id'] as String?) ?? '',
        monthLabel: (data['monthLabel'] as String?) ?? '',
        totalDue: (data['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (data['totalPaid'] as num?)?.toDouble() ?? 0,
        status: (data['status'] as String?) ?? 'Paid',
        lineItems: ((data['lineItems'] as List?) ?? [])
            .map((item) => AccountLineItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        receiptNumber: data['receiptNumber'] as String?,
        paidOn: data['paidOn'] != null
            ? DateTime.tryParse(data['paidOn'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<void> recalculateFees(String studentId) async {
    try {
      await _dio.post('/accounts/student/$studentId/recalculate');
    } catch (e) {
      throw Exception('Failed to recalculate fees: $e');
    }
  }

  Future<List<FeeStructureModel>> getFeeStructures() async {
    try {
      final response = await _dio.get('/fee-structures');
      final data = response.data as List<dynamic>;
      return data.map((item) => FeeStructureModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch fee structures: $e');
    }
  }

  Future<FeeStructureModel> createFeeStructure(FeeStructureModel model) async {
    try {
      final response = await _dio.post('/fee-structures', data: model.toJson());
      return FeeStructureModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create fee structure: $e');
    }
  }

  Future<FeeStructureModel> updateFeeStructure(FeeStructureModel model) async {
    try {
      final response = await _dio.put('/fee-structures/${model.id}', data: model.toJson());
      return FeeStructureModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update fee structure: $e');
    }
  }

  Future<void> deleteFeeStructure(String id) async {
    try {
      await _dio.delete('/fee-structures/$id');
    } catch (e) {
      throw Exception('Failed to delete fee structure: $e');
    }
  }
}
