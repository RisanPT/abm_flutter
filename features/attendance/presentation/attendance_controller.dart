import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/attendance/data/attendance_repository.dart';
import 'package:abm_madrasa/features/attendance/domain/attendance_model.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/data/classroom_repository.dart';
import 'package:abm_madrasa/features/teachers/data/teacher_repository.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_controller.g.dart';

@riverpod
class AttendanceController extends _$AttendanceController {
  @override
  FutureOr<List<AttendanceModel>> build({
    required DateTime date,
    String? classroom,
    String type = 'Student',
    required String shift,
    required String academicYear,
  }) async {
    final instituteId = ref.watch(selectedInstituteProvider).id;
    final year = date.year;
    final month = date.month;

    if (type == 'Teacher') {
      // ── Teacher Attendance ──────────────────────────────────────────────
      // The list is derived from the *scheduled classes* on this date + shift:
      // exactly the teachers who actually have a class that day. This enforces
      // the redesign rule that attendance is gated by the published timetable —
      // rather than showing every shift teacher regardless of whether they teach.
      final timetableData = await ref.read(
        timetableDataProvider((shift: shift, year: year, month: month, academicYear: academicYear)).future,
      );

      final targetDate = DateTime(date.year, date.month, date.day);
      final entriesOnDate = timetableData.schedule.where((e) {
        final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
        return entryDate == targetDate && e.teacherId.isNotEmpty;
      }).toList();

      if (entriesOnDate.isEmpty) {
        // No scheduled classes on this date → no teacher attendance to mark.
        return [];
      }

      // Resolve current teacher names (the schedule carries a snapshot; the
      // teacher record is the source of truth for the display name).
      final allTeachers = await ref.read(teacherRepositoryProvider).getTeachers();
      final nameById = {for (final t in allTeachers) t.id: t.fullName};

      // Distinct teachers who teach on this date, sorted by name.
      final seen = <String>{};
      final scheduledTeachers = <({String id, String name})>[];
      for (final e in entriesOnDate) {
        if (!seen.add(e.teacherId)) continue;
        scheduledTeachers.add((id: e.teacherId, name: nameById[e.teacherId] ?? e.teacherName));
      }
      scheduledTeachers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final existingAttendance = await ref
          .read(attendanceRepositoryProvider)
          .getAttendanceForDate(date, instituteId, type: 'Teacher');

      return scheduledTeachers.map((teacher) {
        final existing = existingAttendance.where((a) => a.teacherId == teacher.id).firstOrNull;
        return existing ??
            AttendanceModel(
              teacherId: teacher.id,
              teacherName: teacher.name,
              date: date,
              status: AttendanceStatus.present,
            );
      }).toList();
    } else {
      // ── Student Attendance ──────────────────────────────────────────────
      // Only load students if a timetable entry exists for this classroom on this date.
      if (classroom == null || classroom.isEmpty) return [];

      // Fetch scheduled classrooms for today
      final scheduledClassrooms = await ref
          .read(scheduledClassroomsForDateProvider(
            (date: date, shift: shift, academicYear: academicYear, year: year, month: month, instituteId: instituteId),
          ).future);

      if (!scheduledClassrooms.contains(classroom)) {
        // No timetable entry for this classroom on this date → attendance unavailable
        return [];
      }

      final allStudents = await ref
          .read(studentRepositoryProvider)
          .getStudents(classroom: classroom);
      final students = allStudents.where((s) => s.shift == shift).toList();

      final existingAttendance = await ref
          .read(attendanceRepositoryProvider)
          .getAttendanceForDate(date, instituteId, type: 'Student');

      return students.map((student) {
        final existing =
            existingAttendance.where((a) => a.studentId == student.id).firstOrNull;
        return existing ??
            AttendanceModel(
              studentId: student.id,
              studentName: student.fullName,
              admissionNumber: student.admissionNumber,
              date: date,
              status: AttendanceStatus.present,
            );
      }).toList();
    }
  }

  void updateStatus(String targetId, AttendanceStatus status, {String type = 'Student'}) {
    if (state.value == null) return;

    final updatedList = state.value!.map((record) {
      if (type == 'Teacher') {
        if (record.teacherId == targetId) return record.copyWith(status: status);
      } else {
        if (record.studentId == targetId) return record.copyWith(status: status);
      }
      return record;
    }).toList();

    state = AsyncValue.data(updatedList);
  }

  void markAll(AttendanceStatus status) {
    final records = state.value;
    if (records == null) return;

    state = AsyncValue.data([
      for (final record in records) record.copyWith(status: status),
    ]);
  }

  Future<void> saveAttendance(String markedBy, {String? classroomName}) async {
    final records = state.value;
    if (records == null || records.isEmpty) return;
    final instituteId = ref.read(selectedInstituteProvider).id;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final date = records.first.date;
      final type = records.first.teacherId != null ? 'Teacher' : 'Student';
      await ref.read(attendanceRepositoryProvider).saveBulkAttendance(
            date: date,
            records: records,
            markedBy: markedBy,
            instituteId: instituteId,
            academicYear: academicYear,
            shift: shift,
            type: type,
            classroomName: classroomName,
          );
      ref.invalidate(attendanceSummaryProvider);
      return records;
    });
  }
}

// ─── Classrooms list ──────────────────────────────────────────────────────────

final attendanceClassroomsProvider = FutureProvider<List<String>>((ref) async {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  final classroomsModels =
      await ref.read(classroomRepositoryProvider).getClassrooms(instituteId: instituteId);
  final classrooms = classroomsModels.map((c) => c.name).toSet().toList()..sort();
  return classrooms;
});

// ─── Scheduled classrooms for a specific date ─────────────────────────────────
/// Returns classrooms that have at least one timetable entry on the given date.
/// Attendance is only available for classrooms in this list.
final scheduledClassroomsForDateProvider = FutureProvider.family<
    List<String>,
    ({DateTime date, String shift, String academicYear, int year, int month, String instituteId})>((ref, args) async {
  // Fetch all timetable data for this shift + month
  final timetableArgs = (
    shift: args.shift,
    year: args.year,
    month: args.month,
    academicYear: args.academicYear,
  );

  final timetableData = await ref.read(timetableDataProvider(timetableArgs).future);

  // Filter entries to only those on the requested date
  final targetDate = DateTime(args.date.year, args.date.month, args.date.day);
  final classroomsOnDate = timetableData.schedule
      .where((entry) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate == targetDate;
      })
      .map((entry) => entry.className)
      .toSet()
      .toList()
    ..sort();

  return classroomsOnDate;
});

// ─── Attendance summary ───────────────────────────────────────────────────────
@riverpod
Future<Map<String, Map<String, int>>> attendanceSummary(Ref ref) async {
  final date = DateTime.now();
  final instituteId = ref.watch(selectedInstituteProvider).id;
  final attendance =
      await ref.read(attendanceRepositoryProvider).getAttendanceForDate(date, instituteId);
  final students = await ref.read(studentRepositoryProvider).getStudents();

  final Map<String, Map<String, int>> summary = {};

  for (final student in students) {
    final classroom = student.classroom;
    summary.putIfAbsent(classroom, () => {'present': 0, 'total': 0});
    summary[classroom]!['total'] = summary[classroom]!['total']! + 1;

    final record = attendance.where((a) => a.studentId == student.id).firstOrNull;
    if (record != null && record.status == AttendanceStatus.present) {
      summary[classroom]!['present'] = summary[classroom]!['present']! + 1;
    }
  }

  return summary;
}
