import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/attendance/data/attendance_repository.dart';
import 'package:abm_madrasa/features/attendance/domain/attendance_model.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/data/classroom_repository.dart';
import 'package:abm_madrasa/features/teachers/data/teacher_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_controller.g.dart';

@riverpod
class AttendanceController extends _$AttendanceController {
  @override
  FutureOr<List<AttendanceModel>> build({required DateTime date, String? classroom, String type = 'Student'}) async {
    final instituteId = ref.watch(selectedInstituteProvider).id;
    
    if (type == 'Teacher') {
      final teachers = await ref.read(teacherRepositoryProvider).getTeachers();
      final existingAttendance = await ref.read(attendanceRepositoryProvider).getAttendanceForDate(date, instituteId, type: 'Teacher');
      
      return teachers.map((teacher) {
        final existing = existingAttendance.where((a) => a.teacherId == teacher.id).firstOrNull;
        return existing ?? AttendanceModel(
          teacherId: teacher.id,
          teacherName: teacher.fullName,
          date: date,
          status: AttendanceStatus.present,
        );
      }).toList();
    } else {
      // 1. Fetch all students for the classroom
      final students = await ref.read(studentRepositoryProvider).getStudents(classroom: classroom);
      
      // 2. Fetch existing attendance for the date
      final existingAttendance = await ref.read(attendanceRepositoryProvider).getAttendanceForDate(date, instituteId, type: 'Student');
      
      // 3. Map students to attendance records (use existing if found, else default to present)
      return students.map((student) {
        final existing = existingAttendance.where((a) => a.studentId == student.id).firstOrNull;
        return existing ?? AttendanceModel(
          studentId: student.id,
          studentName: student.fullName,
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

    state = AsyncValue.data(
      [
        for (final record in records) record.copyWith(status: status),
      ],
    );
  }

  Future<void> saveAttendance(String markedBy) async {
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
        type: type,
      );
      // Invalidate the summary provider when attendance is saved
      ref.invalidate(attendanceSummaryProvider);
      return records;
    });
  }
}

final attendanceClassroomsProvider = FutureProvider<List<String>>((ref) async {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  final classroomsModels = await ref.read(classroomRepositoryProvider).getClassrooms(instituteId: instituteId);
  final classrooms = classroomsModels.map((c) => c.name).toSet().toList()..sort();
  return classrooms;
});

@riverpod
Future<Map<String, Map<String, int>>> attendanceSummary(Ref ref) async {
  final date = DateTime.now();
  final instituteId = ref.watch(selectedInstituteProvider).id;
  final attendance = await ref.read(attendanceRepositoryProvider).getAttendanceForDate(date, instituteId);
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

