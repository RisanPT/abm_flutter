import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/timetable/domain/planning_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(dioProvider));
});

/// Turn any thrown error into a human message, preferring the server's own
/// `{ "message": ... }` body (e.g. permission and validation errors) over the
/// opaque DioException string.
String describeApiError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach the server. Check your connection.';
    }
    return e.message ?? 'Request failed';
  }
  return e.toString().replaceFirst('Exception: ', '');
}

/// Outcome of a "mark holiday" request. When [needsDecision] is true the day
/// still has classes and the caller must choose to reschedule or cancel them.
class HolidayResult {
  const HolidayResult({
    required this.success,
    this.needsDecision = false,
    this.classCount = 0,
    this.message = '',
  });

  final bool success;
  final bool needsDecision;
  final int classCount;
  final String message;
}

class BulkPlanResult {
  const BulkPlanResult({required this.planned, required this.skippedExisting, required this.months});
  final int planned;
  final int skippedExisting;
  final int months;
}

class ReassignResult {
  const ReassignResult({required this.reassigned, required this.total, required this.conflicts});
  final int reassigned;
  final int total;
  final List<Map<String, dynamic>> conflicts;
}

class PlannerRepository {
  PlannerRepository(this._dio);
  final Dio _dio;

  // Format as the UTC calendar day. The backend keys everything on UTC-midnight
  // dates, so we must read UTC components — reading local components would send
  // the wrong day in negative-UTC-offset timezones.
  String _dateKey(DateTime d) {
    final u = d.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  // ── Calendar & summary ────────────────────────────────────────────────────
  Future<List<CalendarCell>> getCalendar({
    required String instituteId,
    required String academicYear,
    required String shift,
    required int year,
    required int month,
  }) async {
    final res = await _dio.get('/shift-plans/calendar', queryParameters: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
      'year': year,
      'month': month,
    });
    final cells = (res.data['cells'] as List<dynamic>? ?? []);
    return cells.map((c) => CalendarCell.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Per-day status for BOTH shifts in the month.
  Future<List<OverviewCell>> getOverview({
    required String instituteId,
    required String academicYear,
    required int year,
    required int month,
  }) async {
    final res = await _dio.get('/shift-plans/overview', queryParameters: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'year': year,
      'month': month,
    });
    final cells = (res.data['cells'] as List<dynamic>? ?? []);
    return cells.map((c) => OverviewCell.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Quick-add one class (auto-plans the day, defaults to Published).
  Future<void> addClass({
    required DateTime date,
    required String shift,
    required String classroomName,
    required String subjectName,
    required String teacherId,
    String startTime = '',
    String endTime = '',
    String room = '',
    bool publish = true,
    required String academicYear,
    required String instituteId,
  }) async {
    await _dio.post('/timetable/day/${_dateKey(date)}/period', data: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
      'classroomName': classroomName,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'publish': publish,
    });
  }

  Future<MonthlySummary> getSummary({
    required String instituteId,
    required String academicYear,
    required String shift,
    required int year,
    required int month,
  }) async {
    final res = await _dio.get('/shift-plans/summary', queryParameters: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
      'year': year,
      'month': month,
    });
    return MonthlySummary.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Day lifecycle ─────────────────────────────────────────────────────────
  Future<void> planDay({
    required DateTime date,
    required String instituteId,
    required String academicYear,
    required String shift,
  }) async {
    await _dio.post('/shift-plans/days/${_dateKey(date)}/plan', data: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
    });
  }

  Future<void> unplanDay({
    required DateTime date,
    required String instituteId,
    required String academicYear,
    required String shift,
  }) async {
    await _dio.delete('/shift-plans/days/${_dateKey(date)}/plan', queryParameters: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
    });
  }

  Future<void> cancelDay({
    required DateTime date,
    required String instituteId,
    required String academicYear,
    required String shift,
  }) async {
    await _dio.post('/shift-plans/days/${_dateKey(date)}/cancel', data: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
    });
  }

  /// Mark a day as holiday. Pass [reschedule]=null on the first call; if the day
  /// has classes the backend returns needsDecision so the UI can prompt.
  Future<HolidayResult> markHoliday({
    required DateTime date,
    required String instituteId,
    required String academicYear,
    required String shift,
    String reason = '',
    bool? reschedule,
    DateTime? targetDate,
  }) async {
    try {
      await _dio.post(
        '/shift-plans/days/${_dateKey(date)}/holiday',
        data: {
          'instituteId': instituteId,
          'academicYear': academicYear,
          'shift': shift,
          'reason': reason,
          if (reschedule != null) 'reschedule': reschedule,
          if (targetDate != null) 'targetDate': _dateKey(targetDate),
        },
      );
      return const HolidayResult(success: true);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 && data is Map && data['needsDecision'] == true) {
        return HolidayResult(
          success: false,
          needsDecision: true,
          classCount: (data['classCount'] as num?)?.toInt() ?? 0,
          message: data['message']?.toString() ?? '',
        );
      }
      rethrow;
    }
  }

  /// Plan a weekday pattern in bulk across a month or the whole academic year.
  Future<BulkPlanResult> bulkPlan({
    required List<int> weekdays,
    required String scope, // 'month' | 'year'
    required int year,
    required int month,
    required String academicYear,
    required String shift,
    required String instituteId,
  }) async {
    final res = await _dio.post('/shift-plans/days/bulk', data: {
      'weekdays': weekdays,
      'scope': scope,
      'year': year,
      'month': month,
      'academicYear': academicYear,
      'shift': shift,
      'instituteId': instituteId,
    });
    final d = res.data as Map<String, dynamic>;
    return BulkPlanResult(
      planned: (d['planned'] as num?)?.toInt() ?? 0,
      skippedExisting: (d['skippedExisting'] as num?)?.toInt() ?? 0,
      months: (d['months'] as num?)?.toInt() ?? 1,
    );
  }

  /// Teacher leave: move one teacher's classes in a date range to a substitute.
  Future<ReassignResult> reassignTeacher({
    required String fromTeacherId,
    required String toTeacherId,
    required DateTime fromDate,
    required DateTime toDate,
    required String shift,
    required String academicYear,
    required String instituteId,
  }) async {
    final res = await _dio.post('/timetable/reassign-teacher', data: {
      'fromTeacherId': fromTeacherId,
      'toTeacherId': toTeacherId,
      'fromDate': _dateKey(fromDate),
      'toDate': _dateKey(toDate),
      'shift': shift,
      'academicYear': academicYear,
      'instituteId': instituteId,
    });
    final d = res.data as Map<String, dynamic>;
    return ReassignResult(
      reassigned: (d['reassigned'] as num?)?.toInt() ?? 0,
      total: (d['total'] as num?)?.toInt() ?? 0,
      conflicts: ((d['conflicts'] as List?) ?? const []).cast<Map<String, dynamic>>(),
    );
  }

  // ── Day timetable editor ──────────────────────────────────────────────────
  Future<DayTimetable> getDayTimetable({
    required DateTime date,
    required String instituteId,
    required String academicYear,
    required String shift,
    String? classroom,
  }) async {
    final res = await _dio.get('/timetable/day/${_dateKey(date)}', queryParameters: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
      if (classroom != null) 'classroom': classroom,
    });
    return DayTimetable.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> saveDayDraft({
    required DateTime date,
    required String instituteId,
    required String academicYear,
    required String shift,
    required String classroomName,
    required List<DayPeriod> periods,
  }) async {
    await _dio.post('/timetable/day/${_dateKey(date)}', data: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
      'classroomName': classroomName,
      'periods': periods
          .map((p) => {
                'period': p.period,
                'subjectName': p.subjectName,
                'teacherId': p.teacherId,
                'startTime': p.startTime,
                'endTime': p.endTime,
                'room': p.room,
              })
          .toList(),
    });
  }

  Future<void> publishDay({
    required DateTime date,
    required String instituteId,
    required String academicYear,
    required String shift,
    String? classroomName,
  }) async {
    await _dio.post('/timetable/day/${_dateKey(date)}/publish', data: {
      'instituteId': instituteId,
      'academicYear': academicYear,
      'shift': shift,
      if (classroomName != null) 'classroomName': classroomName,
    });
  }

  // ── Derived schedules ─────────────────────────────────────────────────────
  Future<List<TeacherClass>> getTeacherSchedule({
    String? teacherId,
    String scope = 'today',
    String? shift,
    required String instituteId,
  }) async {
    final res = await _dio.get('/teacher/schedule', queryParameters: {
      'instituteId': instituteId,
      'scope': scope,
      if (teacherId != null) 'teacherId': teacherId,
      if (shift != null) 'shift': shift,
    });
    final list = (res.data['classes'] as List<dynamic>? ?? []);
    return list.map((c) => TeacherClass.fromJson(c as Map<String, dynamic>)).toList();
  }

  // ── Attendance against a scheduled class ──────────────────────────────────
  /// Existing attendance rows for one scheduled class, as { targetId: status }.
  Future<Map<String, String>> getClassAttendance({
    required String scheduledClassId,
    required String type, // 'Student' | 'Teacher'
    required String instituteId,
  }) async {
    final res = await _dio.get('/attendance', queryParameters: {
      'scheduledClassId': scheduledClassId,
      'type': type,
      'instituteId': instituteId,
    });
    final list = (res.data as List<dynamic>? ?? []);
    final map = <String, String>{};
    for (final r in list) {
      final row = r as Map<String, dynamic>;
      final target = type == 'Teacher' ? row['teacherId'] : row['studentId'];
      final id = target is Map ? target['_id']?.toString() : target?.toString();
      if (id != null) map[id] = row['status']?.toString() ?? 'Absent';
    }
    return map;
  }

  Future<void> markClassAttendance({
    required String scheduledClassId,
    required String type, // 'Student' | 'Teacher'
    required List<Map<String, dynamic>> records,
    String? markedBy,
  }) async {
    await _dio.post('/attendance/bulk', data: {
      'scheduledClassId': scheduledClassId,
      'type': type,
      if (markedBy != null) 'markedBy': markedBy,
      'records': records,
    });
  }

  Future<List<StudentPeriod>> getStudentSchedule({
    String? studentId,
    String? classroom,
    DateTime? date,
    String? shift,
    required String instituteId,
  }) async {
    final res = await _dio.get('/student/schedule', queryParameters: {
      'instituteId': instituteId,
      if (studentId != null) 'studentId': studentId,
      if (classroom != null) 'classroom': classroom,
      if (date != null) 'date': _dateKey(date),
      if (shift != null) 'shift': shift,
    });
    final list = (res.data['periods'] as List<dynamic>? ?? []);
    return list.map((c) => StudentPeriod.fromJson(c as Map<String, dynamic>)).toList();
  }
}
