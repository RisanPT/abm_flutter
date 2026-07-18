import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/planning_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'planner_controller.g.dart';

/// Calendar cells for a given academic year / shift / month.
@riverpod
class PlannerCalendar extends _$PlannerCalendar {
  @override
  Future<List<CalendarCell>> build(String academicYear, String shift, int year, int month) async {
    final repo = ref.watch(plannerRepositoryProvider);
    final instituteId = ref.watch(selectedInstituteProvider).id;
    return repo.getCalendar(
      instituteId: instituteId,
      academicYear: academicYear,
      shift: shift,
      year: year,
      month: month,
    );
  }
}

/// Per-day status for BOTH shifts in the month.
@riverpod
Future<List<OverviewCell>> plannerOverview(
  Ref ref,
  String academicYear,
  int year,
  int month,
) async {
  final repo = ref.watch(plannerRepositoryProvider);
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return repo.getOverview(instituteId: instituteId, academicYear: academicYear, year: year, month: month);
}

/// Monthly summary numbers for the header cards.
@riverpod
Future<MonthlySummary> plannerSummary(
  Ref ref,
  String academicYear,
  String shift,
  int year,
  int month,
) async {
  final repo = ref.watch(plannerRepositoryProvider);
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return repo.getSummary(
    instituteId: instituteId,
    academicYear: academicYear,
    shift: shift,
    year: year,
    month: month,
  );
}

/// A teacher's classes for a scope (today | upcoming | completed).
@riverpod
Future<List<TeacherClass>> teacherSchedule(
  Ref ref,
  String scope, {
  String? teacherId,
  String? shift,
}) async {
  final repo = ref.watch(plannerRepositoryProvider);
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return repo.getTeacherSchedule(
    scope: scope,
    teacherId: teacherId,
    shift: shift,
    instituteId: instituteId,
  );
}

/// A student's (or classroom's) timetable for a date.
@riverpod
Future<List<StudentPeriod>> studentSchedule(
  Ref ref, {
  String? studentId,
  String? classroom,
  DateTime? date,
  String? shift,
}) async {
  final repo = ref.watch(plannerRepositoryProvider);
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return repo.getStudentSchedule(
    studentId: studentId,
    classroom: classroom,
    date: date,
    shift: shift,
    instituteId: instituteId,
  );
}
