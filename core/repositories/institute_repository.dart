import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'institute_repository.g.dart';

class InstituteRepository {
  final Dio _dio;
  InstituteRepository(this._dio);

  Future<List<Institute>> getInstitutes() async {
    try {
      final response = await _dio.get('/institutes');
      final data = response.data as List;
      return data.map((e) => Institute.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch institutes: $e');
    }
  }

  Future<Institute> createInstitute(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/institutes', data: data);
      return Institute.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create institute: $e');
    }
  }

  Future<Institute> updateInstitute(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/institutes/$id', data: data);
      return Institute.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update institute: $e');
    }
  }

  Future<void> deleteInstitute(String id) async {
    try {
      await _dio.delete('/institutes/$id');
    } catch (e) {
      throw Exception('Failed to delete institute: $e');
    }
  }
}

@riverpod
InstituteRepository instituteRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return InstituteRepository(dio);
}
