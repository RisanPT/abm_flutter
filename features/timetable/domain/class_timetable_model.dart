import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_timetable_model.freezed.dart';
part 'class_timetable_model.g.dart';

@freezed
abstract class ClassTimetableEntry with _$ClassTimetableEntry {
  const factory ClassTimetableEntry({
    required String day,
    required int period,
    required String subjectName,
    required String teacherId,
    @Default('') String startTime,
    @Default('') String endTime,
  }) = _ClassTimetableEntry;

  factory ClassTimetableEntry.fromJson(Map<String, dynamic> json) =>
      _$ClassTimetableEntryFromJson(json);
}

@freezed
abstract class ClassTimetable with _$ClassTimetable {
  const factory ClassTimetable({
    required String classroomName,
    required List<ClassTimetableEntry> schedule,
  }) = _ClassTimetable;

  factory ClassTimetable.fromJson(Map<String, dynamic> json) =>
      _$ClassTimetableFromJson(json);
}
