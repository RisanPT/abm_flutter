// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarCell _$CalendarCellFromJson(Map<String, dynamic> json) =>
    _CalendarCell(
      date: DateTime.parse(json['date'] as String),
      displayStatus: json['displayStatus'] as String,
      dayStatus: json['dayStatus'] as String? ?? 'Planned',
      isHoliday: json['isHoliday'] as bool? ?? false,
      holidayReason: json['holidayReason'] as String? ?? '',
      classCount: (json['classCount'] as num?)?.toInt() ?? 0,
      publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CalendarCellToJson(_CalendarCell instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'displayStatus': instance.displayStatus,
      'dayStatus': instance.dayStatus,
      'isHoliday': instance.isHoliday,
      'holidayReason': instance.holidayReason,
      'classCount': instance.classCount,
      'publishedCount': instance.publishedCount,
    };

_ShiftCellInfo _$ShiftCellInfoFromJson(Map<String, dynamic> json) =>
    _ShiftCellInfo(
      displayStatus: json['displayStatus'] as String? ?? 'Empty',
      classCount: (json['classCount'] as num?)?.toInt() ?? 0,
      publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
      isHoliday: json['isHoliday'] as bool? ?? false,
    );

Map<String, dynamic> _$ShiftCellInfoToJson(_ShiftCellInfo instance) =>
    <String, dynamic>{
      'displayStatus': instance.displayStatus,
      'classCount': instance.classCount,
      'publishedCount': instance.publishedCount,
      'isHoliday': instance.isHoliday,
    };

_OverviewCell _$OverviewCellFromJson(Map<String, dynamic> json) =>
    _OverviewCell(
      date: DateTime.parse(json['date'] as String),
      shifts:
          (json['shifts'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, ShiftCellInfo.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$OverviewCellToJson(_OverviewCell instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'shifts': instance.shifts,
    };

_MonthlySummary _$MonthlySummaryFromJson(Map<String, dynamic> json) =>
    _MonthlySummary(
      academicYear: json['academicYear'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      shift: json['shift'] as String? ?? 'Shift-1',
      plannedDays: (json['plannedDays'] as num?)?.toInt() ?? 0,
      holidays: (json['holidays'] as num?)?.toInt() ?? 0,
      draftTimetables: (json['draftTimetables'] as num?)?.toInt() ?? 0,
      publishedTimetables: (json['publishedTimetables'] as num?)?.toInt() ?? 0,
      scheduledClasses: (json['scheduledClasses'] as num?)?.toInt() ?? 0,
      teachersAssigned: (json['teachersAssigned'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MonthlySummaryToJson(_MonthlySummary instance) =>
    <String, dynamic>{
      'academicYear': instance.academicYear,
      'year': instance.year,
      'month': instance.month,
      'shift': instance.shift,
      'plannedDays': instance.plannedDays,
      'holidays': instance.holidays,
      'draftTimetables': instance.draftTimetables,
      'publishedTimetables': instance.publishedTimetables,
      'scheduledClasses': instance.scheduledClasses,
      'teachersAssigned': instance.teachersAssigned,
    };

_DayPeriod _$DayPeriodFromJson(Map<String, dynamic> json) => _DayPeriod(
  id: json['id'] as String?,
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  classroomName: json['classroomName'] as String? ?? '',
  period: (json['period'] as num).toInt(),
  subjectName: json['subjectName'] as String? ?? '',
  teacherId: json['teacherId'] as String?,
  teacherName: json['teacherName'] as String?,
  startTime: json['startTime'] as String? ?? '',
  endTime: json['endTime'] as String? ?? '',
  room: json['room'] as String? ?? '',
  status: json['status'] as String? ?? 'Draft',
  shift: json['shift'] as String? ?? 'Shift-1',
);

Map<String, dynamic> _$DayPeriodToJson(_DayPeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date?.toIso8601String(),
      'classroomName': instance.classroomName,
      'period': instance.period,
      'subjectName': instance.subjectName,
      'teacherId': instance.teacherId,
      'teacherName': instance.teacherName,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'room': instance.room,
      'status': instance.status,
      'shift': instance.shift,
    };

_TeacherOption _$TeacherOptionFromJson(Map<String, dynamic> json) =>
    _TeacherOption(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      subjects:
          (json['subjects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      specialty: json['specialty'] as String? ?? '',
    );

Map<String, dynamic> _$TeacherOptionToJson(_TeacherOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'title': instance.title,
      'photoUrl': instance.photoUrl,
      'subjects': instance.subjects,
      'specialty': instance.specialty,
    };

_ClassroomOption _$ClassroomOptionFromJson(Map<String, dynamic> json) =>
    _ClassroomOption(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      subjects:
          (json['subjects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ClassroomOptionToJson(_ClassroomOption instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'subjects': instance.subjects,
    };

_DayTimetable _$DayTimetableFromJson(Map<String, dynamic> json) =>
    _DayTimetable(
      date: DateTime.parse(json['date'] as String),
      shift: json['shift'] as String? ?? 'Shift-1',
      isPlanned: json['isPlanned'] as bool? ?? false,
      dayStatus: json['dayStatus'] as String? ?? 'Empty',
      isHoliday: json['isHoliday'] as bool? ?? false,
      periods:
          (json['periods'] as List<dynamic>?)
              ?.map((e) => DayPeriod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      teachers:
          (json['teachers'] as List<dynamic>?)
              ?.map((e) => TeacherOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      classrooms:
          (json['classrooms'] as List<dynamic>?)
              ?.map((e) => ClassroomOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DayTimetableToJson(_DayTimetable instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'shift': instance.shift,
      'isPlanned': instance.isPlanned,
      'dayStatus': instance.dayStatus,
      'isHoliday': instance.isHoliday,
      'periods': instance.periods,
      'teachers': instance.teachers,
      'classrooms': instance.classrooms,
    };

_TeacherClass _$TeacherClassFromJson(Map<String, dynamic> json) =>
    _TeacherClass(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      shift: json['shift'] as String? ?? 'Shift-1',
      classroomName: json['classroomName'] as String? ?? '',
      period: (json['period'] as num).toInt(),
      subjectName: json['subjectName'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      room: json['room'] as String? ?? '',
      status: json['status'] as String? ?? 'Published',
      attendanceEnabled: json['attendanceEnabled'] as bool? ?? false,
      alreadyMarked: json['alreadyMarked'] as bool? ?? false,
    );

Map<String, dynamic> _$TeacherClassToJson(_TeacherClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'shift': instance.shift,
      'classroomName': instance.classroomName,
      'period': instance.period,
      'subjectName': instance.subjectName,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'room': instance.room,
      'status': instance.status,
      'attendanceEnabled': instance.attendanceEnabled,
      'alreadyMarked': instance.alreadyMarked,
    };

_StudentPeriod _$StudentPeriodFromJson(Map<String, dynamic> json) =>
    _StudentPeriod(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      classroomName: json['classroomName'] as String? ?? '',
      period: (json['period'] as num).toInt(),
      subjectName: json['subjectName'] as String? ?? '',
      teacherName: json['teacherName'] as String?,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      room: json['room'] as String? ?? '',
      status: json['status'] as String? ?? 'Published',
    );

Map<String, dynamic> _$StudentPeriodToJson(_StudentPeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'classroomName': instance.classroomName,
      'period': instance.period,
      'subjectName': instance.subjectName,
      'teacherName': instance.teacherName,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'room': instance.room,
      'status': instance.status,
    };
