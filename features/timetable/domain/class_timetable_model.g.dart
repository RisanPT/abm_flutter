// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_timetable_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClassTimetableEntry _$ClassTimetableEntryFromJson(Map<String, dynamic> json) =>
    _ClassTimetableEntry(
      day: json['day'] as String,
      period: (json['period'] as num).toInt(),
      subjectName: json['subjectName'] as String,
      teacherId: json['teacherId'] as String,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );

Map<String, dynamic> _$ClassTimetableEntryToJson(
  _ClassTimetableEntry instance,
) => <String, dynamic>{
  'day': instance.day,
  'period': instance.period,
  'subjectName': instance.subjectName,
  'teacherId': instance.teacherId,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
};

_ClassTimetable _$ClassTimetableFromJson(Map<String, dynamic> json) =>
    _ClassTimetable(
      classroomName: json['classroomName'] as String,
      schedule: (json['schedule'] as List<dynamic>)
          .map((e) => ClassTimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ClassTimetableToJson(_ClassTimetable instance) =>
    <String, dynamic>{
      'classroomName': instance.classroomName,
      'schedule': instance.schedule,
    };
