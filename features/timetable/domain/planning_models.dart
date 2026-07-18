import 'package:freezed_annotation/freezed_annotation.dart';

part 'planning_models.freezed.dart';
part 'planning_models.g.dart';

/// One calendar cell returned by GET /shift-plans/calendar.
@freezed
abstract class CalendarCell with _$CalendarCell {
  const factory CalendarCell({
    required DateTime date,
    required String displayStatus, // Empty|Planned|Draft|Published|Holiday|Completed|Cancelled
    @Default('Planned') String dayStatus,
    @Default(false) bool isHoliday,
    @Default('') String holidayReason,
    @Default(0) int classCount,
    @Default(0) int publishedCount,
  }) = _CalendarCell;

  factory CalendarCell.fromJson(Map<String, dynamic> json) =>
      _$CalendarCellFromJson(json);
}

/// One shift's status within an overview cell.
@freezed
abstract class ShiftCellInfo with _$ShiftCellInfo {
  const factory ShiftCellInfo({
    @Default('Empty') String displayStatus,
    @Default(0) int classCount,
    @Default(0) int publishedCount,
    @Default(false) bool isHoliday,
  }) = _ShiftCellInfo;

  factory ShiftCellInfo.fromJson(Map<String, dynamic> json) => _$ShiftCellInfoFromJson(json);
}

/// One calendar cell showing BOTH shifts (GET /shift-plans/overview).
@freezed
abstract class OverviewCell with _$OverviewCell {
  const factory OverviewCell({
    required DateTime date,
    @Default({}) Map<String, ShiftCellInfo> shifts,
  }) = _OverviewCell;

  factory OverviewCell.fromJson(Map<String, dynamic> json) => _$OverviewCellFromJson(json);
}

/// GET /shift-plans/summary
@freezed
abstract class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    @Default('') String academicYear,
    @Default(0) int year,
    @Default(0) int month,
    @Default('Shift-1') String shift,
    @Default(0) int plannedDays,
    @Default(0) int holidays,
    @Default(0) int draftTimetables,
    @Default(0) int publishedTimetables,
    @Default(0) int scheduledClasses,
    @Default(0) int teachersAssigned,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
}

/// A single scheduled class/period as shown in the day editor.
@freezed
abstract class DayPeriod with _$DayPeriod {
  const factory DayPeriod({
    @JsonKey(name: 'id') String? id,
    DateTime? date,
    @Default('') String classroomName,
    required int period,
    @Default('') String subjectName,
    String? teacherId,
    String? teacherName,
    @Default('') String startTime,
    @Default('') String endTime,
    @Default('') String room,
    @Default('Draft') String status,
    @Default('Shift-1') String shift,
  }) = _DayPeriod;

  factory DayPeriod.fromJson(Map<String, dynamic> json) =>
      _$DayPeriodFromJson(json);
}

@freezed
abstract class TeacherOption with _$TeacherOption {
  const factory TeacherOption({
    required String id,
    @Default('') String fullName,
    @Default('') String title,
    String? photoUrl,
    @Default([]) List<String> subjects,
    @Default('') String specialty,
  }) = _TeacherOption;

  factory TeacherOption.fromJson(Map<String, dynamic> json) =>
      _$TeacherOptionFromJson(json);

  const TeacherOption._();

  /// The teacher's subject = their manually-set Specialty (the field on the
  /// teacher form). This is the single source of truth; the auto-tracked
  /// `subjects` list is not used for the teacher's displayed subject.
  String get primarySubject => specialty;

  /// The specialty when the classroom actually offers it (to auto-fill the
  /// subject dropdown); otherwise empty and the user picks the subject.
  String matchingSubject(List<String> classroomSubjects) =>
      specialty.isNotEmpty && classroomSubjects.contains(specialty) ? specialty : '';
}

@freezed
abstract class ClassroomOption with _$ClassroomOption {
  const factory ClassroomOption({
    @JsonKey(name: '_id') String? id,
    @Default('') String name,
    @Default([]) List<String> subjects,
  }) = _ClassroomOption;

  factory ClassroomOption.fromJson(Map<String, dynamic> json) =>
      _$ClassroomOptionFromJson(json);
}

/// GET /timetable/day/:date — the day editor payload.
@freezed
abstract class DayTimetable with _$DayTimetable {
  const factory DayTimetable({
    required DateTime date,
    @Default('Shift-1') String shift,
    @Default(false) bool isPlanned,
    @Default('Empty') String dayStatus,
    @Default(false) bool isHoliday,
    @Default([]) List<DayPeriod> periods,
    @Default([]) List<TeacherOption> teachers,
    @Default([]) List<ClassroomOption> classrooms,
  }) = _DayTimetable;

  factory DayTimetable.fromJson(Map<String, dynamic> json) =>
      _$DayTimetableFromJson(json);
}

/// One class in a teacher's schedule (GET /teacher/schedule).
@freezed
abstract class TeacherClass with _$TeacherClass {
  const factory TeacherClass({
    @JsonKey(name: 'id') required String id,
    required DateTime date,
    @Default('Shift-1') String shift,
    @Default('') String classroomName,
    required int period,
    @Default('') String subjectName,
    @Default('') String startTime,
    @Default('') String endTime,
    @Default('') String room,
    @Default('Published') String status,
    @Default(false) bool attendanceEnabled,
    @Default(false) bool alreadyMarked,
  }) = _TeacherClass;

  factory TeacherClass.fromJson(Map<String, dynamic> json) =>
      _$TeacherClassFromJson(json);
}

/// One period in a student's day (GET /student/schedule).
@freezed
abstract class StudentPeriod with _$StudentPeriod {
  const factory StudentPeriod({
    @JsonKey(name: 'id') required String id,
    required DateTime date,
    @Default('') String classroomName,
    required int period,
    @Default('') String subjectName,
    String? teacherName,
    @Default('') String startTime,
    @Default('') String endTime,
    @Default('') String room,
    @Default('Published') String status,
  }) = _StudentPeriod;

  factory StudentPeriod.fromJson(Map<String, dynamic> json) =>
      _$StudentPeriodFromJson(json);
}
