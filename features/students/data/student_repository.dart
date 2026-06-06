import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'student_repository.g.dart';

@Riverpod(keepAlive: true)
StudentRepository studentRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return StudentRepository(dio);
}

class StudentRepository {
  final Dio _dio;
  StudentRepository(this._dio);

  Map<String, dynamic> _studentPayload(StudentModel student) {
    final data = Map<String, dynamic>.from(student.toJson());
    data.remove('_id');
    data.remove('attendancePercentage');
    data.remove('scholarshipAmount');
    return data;
  }

  Future<List<StudentModel>> getStudents({String? query, String? classroom}) async {
    try {
      final response = await _dio.get('/students', queryParameters: {
        'search': query,
        'grade': classroom,
      }..removeWhere((_ , v) => v == null));

      final List<dynamic> data = response.data;
      return data.map((json) => StudentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<StudentModel> addStudent(StudentModel student) async {
    try {
      final response = await _dio.post('/students', data: _studentPayload(student));
      return StudentModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add student: $e');
    }
  }

  Future<StudentModel> getStudentById(String id) async {
    try {
      final response = await _dio.get('/students/$id');
      return StudentModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
    }
  }

  Future<StudentModel> updateStudent(StudentModel student) async {
    try {
      final response = await _dio.patch('/students/${student.id}', data: _studentPayload(student));
      return StudentModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  Future<String> uploadStudentImage({
    required List<int> bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';
      final response = await _dio.post(
        '/students/upload-image',
        data: {
          'dataUri': dataUri,
          'fileName': fileName,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return response.data['photoUrl'] as String;
    } catch (e) {
      throw Exception('Failed to upload student image: $e');
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _dio.delete('/students/$id');
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  Future<int> getSiblingCount(String parentId) async {
    try {
      final response = await _dio.get('/students/siblings-count/$parentId');
      return response.data['count'] as int;
    } catch (e) {
      return 0;
    }
  }
}
