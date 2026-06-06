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
    required String studentId,
    String? studentName, // Populated from studentId object if available
    required DateTime date,
    @Default(AttendanceStatus.absent) AttendanceStatus status,
    @Default('Admin') String markedBy,
    String? remarks,
  }) = _AttendanceModel;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => 
      _$AttendanceModelFromJson(_preProcessJson(json));

  static Map<String, dynamic> _preProcessJson(Map<String, dynamic> json) {
    if (json['studentId'] is Map<String, dynamic>) {
      final studentMap = json['studentId'] as Map<String, dynamic>;
      return {
        ...json,
        'studentId': studentMap['_id'] ?? '',
        'studentName': studentMap['fullName'] ?? studentMap['name'] ?? '',
      };
    }
    return json;
  }
}
