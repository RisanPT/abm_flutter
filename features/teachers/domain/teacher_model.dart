class TeacherScheduleEntry {
  const TeacherScheduleEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.className,
    required this.subject,
    this.room = '',
  });

  final String day;
  final String startTime;
  final String endTime;
  final String className;
  final String subject;
  final String room;

  factory TeacherScheduleEntry.fromJson(Map<String, dynamic> json) {
    return TeacherScheduleEntry(
      day: json['day'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      className: json['className'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      room: json['room'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'className': className,
        'subject': subject,
        'room': room,
      };
}

class TeacherModel {
  const TeacherModel({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.title,
    required this.phone,
    required this.email,
    required this.specialty,
    required this.joinedDate,
    required this.monthlySalary,
    required this.subjects,
    required this.classes,
    required this.schedule,
    this.photoUrl,
    this.isActive = true,
    this.password,
  });

  final String id;
  final String employeeId;
  final String fullName;
  final String title;
  final String phone;
  final String email;
  final String specialty;
  final DateTime joinedDate;
  final double monthlySalary;
  final List<String> subjects;
  final List<String> classes;
  final List<TeacherScheduleEntry> schedule;
  final String? photoUrl;
  final bool isActive;
  final String? password;

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['_id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      joinedDate: DateTime.tryParse(json['joinedDate'] as String? ?? '') ??
          DateTime.now(),
      monthlySalary: (json['monthlySalary'] as num?)?.toDouble() ?? 0,
      subjects: (json['subjects'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      classes: (json['classes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      schedule: (json['schedule'] as List<dynamic>? ?? const [])
          .map((item) =>
              TeacherScheduleEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      photoUrl: json['photoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'employeeId': employeeId,
        'fullName': fullName,
        'title': title,
        'phone': phone,
        'email': email,
        'specialty': specialty,
        'joinedDate': joinedDate.toIso8601String(),
        'monthlySalary': monthlySalary,
        'subjects': subjects,
        'classes': classes,
        'schedule': schedule.map((entry) => entry.toJson()).toList(),
        'photoUrl': photoUrl,
        'isActive': isActive,
        if (password != null) 'password': password,
      };
}
