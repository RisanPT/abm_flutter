import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/timetable/domain/class_timetable_model.dart';
import 'package:abm_madrasa/features/timetable/domain/timetable_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetableRepository(dio);
});

class TimetableRepository {
  TimetableRepository(this._dio);

  final Dio _dio;

  Future<TimetableData> getTimetable() async {
    try {
      final response = await _dio.get('/timetable');
      return TimetableData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch timetable: $e');
    }
  }

  Future<ClassTimetable> getClassroomTimetable(String className) async {
    try {
      final response = await _dio.get('/timetable/classroom/$className');
      return ClassTimetable.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch classroom timetable: $e');
    }
  }

  Future<ClassTimetable> updateClassroomTimetable(
    String className,
    List<ClassTimetableEntry> schedule,
  ) async {
    try {
      final response = await _dio.post(
        '/timetable/classroom/$className',
        data: {
          'schedule': schedule.map((e) => e.toJson()).toList(),
        },
      );
      return ClassTimetable.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update classroom timetable: $e');
    }
  }
}
