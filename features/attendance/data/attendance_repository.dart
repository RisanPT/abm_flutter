import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/attendance/domain/attendance_model.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_repository.g.dart';

@Riverpod(keepAlive: true)
AttendanceRepository attendanceRepository(Ref ref) {
  final dioClient = ref.watch(dioProvider);
  return AttendanceRepository(dioClient);
}

class AttendanceRepository {
  final Dio _dio;
  final _dateFormatter = DateFormat('yyyy-MM-dd');
  AttendanceRepository(this._dio);

  Future<List<AttendanceModel>> getAttendanceForDate(DateTime date, String instituteId) async {
    try {
      final dateStr = _dateFormatter.format(date);
      final response = await _dio.get('/attendance', queryParameters: {
        'date': dateStr,
        'instituteId': instituteId
      });
      final List<dynamic> data = response.data;
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  Future<void> saveBulkAttendance({
    required DateTime date,
    required List<AttendanceModel> records,
    required String markedBy,
    required String instituteId,
  }) async {
    try {
      final data = {
        'date': _dateFormatter.format(date),
        'markedBy': markedBy,
        'instituteId': instituteId,
        'records': records.map((r) => {
          'studentId': r.studentId,
          'status': _statusToString(r.status),
          'remarks': r.remarks,
        }).toList(),
      };
      await _dio.post('/attendance/bulk', data: data);
    } catch (e) {
      throw Exception('Failed to save attendance: $e');
    }
  }

  Future<void> staffCheckIn({
    required String instituteId,
    required double lat,
    required double lng,
    required String verificationMethod,
  }) async {
    try {
      await _dio.post('/attendance/check-in', data: {
        'instituteId': instituteId,
        'location': {
          'latitude': lat,
          'longitude': lng,
        },
        'verificationMethod': verificationMethod,
      });
    } catch (e) {
      throw Exception('Check-in failed: $e');
    }
  }

  String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}

