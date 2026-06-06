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

  Future<void> processPayment({
    required String studentId,
    required double amount,
  }) async {
    try {
      await _dio.post('/accounts/student/$studentId/pay', data: {'amount': amount});
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }
}
