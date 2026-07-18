import 'package:abm_madrasa/features/students/domain/classroom_model.dart';

class TimetableTeacherSummary {
  const TimetableTeacherSummary({
    required this.id,
    required this.fullName,
    required this.title,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String title;
  final String? photoUrl;

  factory TimetableTeacherSummary.fromJson(Map<String, dynamic> json) {
    return TimetableTeacherSummary(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.className,
    required this.subject,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.teacherPhotoUrl,
    this.period,
    this.shift = 'Shift-1',
  });

  final String id;
  final String teacherId;
  final String teacherName;
  final String className;
  final String subject;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String room;
  final String? teacherPhotoUrl;
  final int? period;
  final String shift;

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      // The API serialises these as `classroomName` / `subjectName`; keep the
      // legacy keys as a fallback so older payloads still parse.
      className: (json['classroomName'] ?? json['className']) as String? ?? '',
      subject: (json['subjectName'] ?? json['subject']) as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      room: json['room'] as String? ?? '',
      teacherPhotoUrl: json['teacherPhotoUrl'] as String?,
      period: json['period'] as int?,
      shift: json['shift'] as String? ?? 'Shift-1',
    );
  }
}

class TimetableData {
  const TimetableData({
    required this.classes,
    required this.teachers,
    required this.schedule,
    required this.allClassrooms,
  });

  final List<String> classes;
  final List<TimetableTeacherSummary> teachers;
  final List<TimetableEntry> schedule;
  final List<ClassroomModel> allClassrooms;

  factory TimetableData.fromJson(Map<String, dynamic> json) {
    final rawTeachers = json['teachers'] as List<dynamic>? ?? const [];
    final rawSchedule = json['schedule'] as List<dynamic>? ?? const [];
    final rawClassrooms = json['allClassrooms'] as List<dynamic>? ?? const [];

    return TimetableData(
      classes: (json['classes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      teachers: rawTeachers
          .whereType<Map<String, dynamic>>()
          .map(TimetableTeacherSummary.fromJson)
          .toList(),
      schedule: rawSchedule
          .whereType<Map<String, dynamic>>()
          .map(TimetableEntry.fromJson)
          .toList(),
      allClassrooms: rawClassrooms
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => ClassroomModel.fromJson({
              '_id': item['_id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'description': item['description']?.toString(),
              'subjects': (item['subjects'] as List<dynamic>? ?? const [])
                  .map((subject) => subject.toString())
                  .where((subject) => subject.isNotEmpty)
                  .toList(),
            }),
          )
          .toList(),
    );
  }
}
