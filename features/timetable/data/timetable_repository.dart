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

  /// Fetch global timetable for a specific shift + month.
  Future<TimetableData> getTimetable(
    String instituteId,
    String shift, {
    required int year,
    required int month,
    required String academicYear,
  }) async {
    try {
      final response = await _dio.get('/timetable', queryParameters: {
        'instituteId': instituteId,
        'shift': shift,
        'year': year,
        'month': month,
        'academicYear': academicYear,
      });
      return TimetableData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch timetable: $e');
    }
  }

  /// Fetch the list of dates that already have timetable entries
  /// (i.e., scheduled class dates with assigned subject+teacher).
  Future<List<DateTime>> getScheduledDates(
    String instituteId,
    String shift, {
    required int year,
    required int month,
    required String academicYear,
  }) async {
    try {
      final response = await _dio.get('/timetable/scheduled-dates', queryParameters: {
        'instituteId': instituteId,
        'shift': shift,
        'year': year,
        'month': month,
        'academicYear': academicYear,
      });
      final data = response.data as Map<String, dynamic>;
      final rawDates = data['dates'] as List<dynamic>? ?? [];
      return rawDates.map((d) => DateTime.parse(d as String)).toList();
    } catch (e) {
      throw Exception('Failed to fetch scheduled dates: $e');
    }
  }

  /// Fetch timetable for a specific classroom + shift + month.
  Future<ClassTimetable> getClassroomTimetable(
    String className,
    String instituteId,
    String shift, {
    required int year,
    required int month,
    required String academicYear,
  }) async {
    try {
      final response = await _dio.get(
        '/timetable/classroom/$className',
        queryParameters: {
          'instituteId': instituteId,
          'shift': shift,
          'year': year,
          'month': month,
          'academicYear': academicYear,
        },
      );
      return ClassTimetable.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch classroom timetable: $e');
    }
  }

  /// Save/update the timetable for a classroom for a specific month.
  Future<ClassTimetable> updateClassroomTimetable(
    String className,
    String instituteId,
    String shift,
    String academicYear,
    int year,
    int month,
    List<ClassTimetableEntry> schedule,
  ) async {
    try {
      final response = await _dio.post(
        '/timetable/classroom/$className',
        data: {
          'schedule': schedule.map((e) => {
            'date': e.date.toIso8601String(),
            'period': e.period,
            'subjectName': e.subjectName,
            'teacherId': e.teacherId,
            'startTime': e.startTime,
            'endTime': e.endTime,
          }).toList(),
          'instituteId': instituteId,
          'shift': shift,
          'academicYear': academicYear,
          'year': year,
          'month': month,
        },
      );
      return ClassTimetable.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update classroom timetable: $e');
    }
  }
}
