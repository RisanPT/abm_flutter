import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_model.freezed.dart';
part 'attendance_model.g.dart';

enum AttendanceStatus {
  @JsonValue('Present')
  present,
  @JsonValue('Absent')
  absent,
  @JsonValue('Late')
  late,
}

@freezed
abstract class AttendanceModel with _$AttendanceModel {
  const factory AttendanceModel({
    @JsonKey(name: '_id') String? id,
    String? studentId,
    String? studentName, // Populated from studentId object if available
    String? admissionNumber, // The student's roll number or admission ID
    String? teacherId,
    String? teacherName, // Populated from teacherId object if available
    required DateTime date,
    @Default(AttendanceStatus.absent) AttendanceStatus status,
    @Default('Admin') String markedBy,
    String? remarks,
  }) = _AttendanceModel;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => 
      _$AttendanceModelFromJson(_preProcessJson(json));

  static Map<String, dynamic> _preProcessJson(Map<String, dynamic> json) {
    var modifiedJson = Map<String, dynamic>.from(json);
    
    if (modifiedJson['studentId'] is Map<String, dynamic>) {
      final studentMap = modifiedJson['studentId'] as Map<String, dynamic>;
      modifiedJson['studentId'] = studentMap['_id'] ?? '';
      modifiedJson['studentName'] = studentMap['fullName'] ?? studentMap['name'] ?? '';
      modifiedJson['admissionNumber'] = studentMap['studentId']?.toString() ?? studentMap['admissionNumber']?.toString() ?? '';
    }
    
    if (modifiedJson['teacherId'] is Map<String, dynamic>) {
      final teacherMap = modifiedJson['teacherId'] as Map<String, dynamic>;
      modifiedJson['teacherId'] = teacherMap['_id'] ?? '';
      modifiedJson['teacherName'] = teacherMap['fullName'] ?? teacherMap['name'] ?? '';
    }
    
    return modifiedJson;
  }
}
