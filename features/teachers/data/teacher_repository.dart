import 'dart:convert';

import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/teachers/domain/teacher_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TeacherRepository(dio);
});

class TeacherRepository {
  TeacherRepository(this._dio);

  final Dio _dio;

  Future<List<TeacherModel>> getTeachers({String? query}) async {
    try {
      final response = await _dio.get(
        '/teachers',
        queryParameters: {
          'search': query,
        }..removeWhere((key, value) => value == null || value == ''),
      );
      final data = response.data as List<dynamic>;
      return data
          .map((item) => TeacherModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  Future<TeacherModel> addTeacher(TeacherModel teacher) async {
    try {
      final response = await _dio.post('/teachers', data: _payload(teacher));
      return TeacherModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add teacher: $e');
    }
  }

  Future<TeacherModel> updateTeacher(TeacherModel teacher) async {
    try {
      final response =
          await _dio.patch('/teachers/${teacher.id}', data: _payload(teacher));
      return TeacherModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  Future<void> deleteTeacher(String id) async {
    try {
      await _dio.delete('/teachers/$id');
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }

  Future<String> uploadTeacherImage({
    required List<int> bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final response = await _dio.post(
        '/teachers/upload-image',
        data: {
          'dataUri': 'data:$mimeType;base64,${base64Encode(bytes)}',
          'fileName': fileName,
        },
      );
      return response.data['photoUrl'] as String;
    } catch (e) {
      throw Exception('Failed to upload teacher image: $e');
    }
  }

  Future<TeacherModel> updateTeacherSchedule(String id, List<TeacherScheduleEntry> schedule) async {
    try {
      final response = await _dio.patch(
        '/teachers/$id/schedule',
        data: {'schedule': schedule.map((e) => e.toJson()).toList()},
      );
      return TeacherModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update teacher schedule: $e');
    }
  }

  Map<String, dynamic> _payload(TeacherModel teacher) {
    final data = Map<String, dynamic>.from(teacher.toJson());
    data.remove('_id');
    return data;
  }
}
