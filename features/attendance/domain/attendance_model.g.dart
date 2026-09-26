// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) =>
    _AttendanceModel(
      id: json['_id'] as String?,
      studentId: json['studentId'] as String?,
      studentName: json['studentName'] as String?,
      admissionNumber: json['admissionNumber'] as String?,
      teacherId: json['teacherId'] as String?,
      teacherName: json['teacherName'] as String?,
      employeeId: json['employeeId'] as String?,
      date: DateTime.parse(json['date'] as String),
      status:
          $enumDecodeNullable(_$AttendanceStatusEnumMap, json['status']) ??
          AttendanceStatus.absent,
      markedBy: json['markedBy'] as String? ?? 'Admin',
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AttendanceModelToJson(_AttendanceModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'teacherId': instance.teacherId,
      'teacherName': instance.teacherName,
      'employeeId': instance.employeeId,
      'date': instance.date.toIso8601String(),
      'status': _$AttendanceStatusEnumMap[instance.status]!,
      'markedBy': instance.markedBy,
      'remarks': instance.remarks,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$AttendanceStatusEnumMap = {
  AttendanceStatus.present: 'Present',
  AttendanceStatus.absent: 'Absent',
  AttendanceStatus.late: 'Late',
};
