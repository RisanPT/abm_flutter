import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'classroom_repository.g.dart';

class ClassroomRepository {
  final Dio _dio;

  ClassroomRepository(this._dio);

  Future<List<ClassroomModel>> getClassrooms({String? instituteId}) async {
    try {
      final response = await _dio.get(
        '/classrooms',
        queryParameters: {
          if (instituteId != null) 'instituteId': instituteId,
        },
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ClassroomModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load classrooms: $e');
    }
  }

  Future<ClassroomModel> addClassroom(String name, {String? description, required String instituteId}) async {
    try {
      final response = await _dio.post(
        '/classrooms',
        data: {
          'name': name,
          'description': description,
          'instituteId': instituteId,
        },
      );
      return ClassroomModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add classroom: $e');
    }
  }

  Future<ClassroomModel> updateClassroomSubjects(String id, List<String> subjects) async {
    try {
      final response = await _dio.patch(
        '/classrooms/$id/subjects',
        data: {'subjects': subjects},
      );
      return ClassroomModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update subjects: $e');
    }
  }
}

@riverpod
ClassroomRepository classroomRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ClassroomRepository(dio);
}
