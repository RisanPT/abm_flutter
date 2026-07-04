// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudentModel _$StudentModelFromJson(Map<String, dynamic> json) =>
    _StudentModel(
      id: json['_id'] as String,
      fullName: json['fullName'] as String,
      admissionNumber: json['studentId'] as String,
      classroom: json['grade'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      bloodGroup: json['bloodGroup'] as String?,
      guardianName: json['guardianName'] as String? ?? 'Unknown',
      guardianContact: json['parentContact'] as String,
      address: json['address'] as String,
      admissionDate: DateTime.parse(json['enrollmentDate'] as String),
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      photoUrl: json['photoUrl'] as String?,
      parentIqamaId: json['parentIqamaId'] as String?,
      parentPassportId: json['parentPassportId'] as String?,
      fatherWhatsapp: json['fatherWhatsapp'] as String?,
      motherWhatsapp: json['motherWhatsapp'] as String?,
      country: json['country'] as String? ?? 'India',
      state: json['state'] as String?,
      studentIqamaNumber: json['studentIqamaNumber'] as String?,
      studentIqamaUrl: json['studentIqamaUrl'] as String?,
      fatherOccupation: json['fatherOccupation'] as String?,
      motherOccupation: json['motherOccupation'] as String?,
      numberOfChildren: (json['numberOfChildren'] as num?)?.toInt() ?? 0,
      childrenAges:
          (json['childrenAges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      shift: json['shift'] as String?,
      needsTransportation: json['needsTransportation'] as bool? ?? false,
      transportationFee: (json['transportationFee'] as num?)?.toDouble() ?? 0,
      hasConcession: json['hasConcession'] as bool? ?? false,
      instituteId: json['instituteId'] as String? ?? '664c39f00000000000000001',
      scholarshipAmount: (json['scholarshipAmount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StudentModelToJson(_StudentModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'fullName': instance.fullName,
      'studentId': instance.admissionNumber,
      'grade': instance.classroom,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'gender': _$GenderEnumMap[instance.gender]!,
      'bloodGroup': instance.bloodGroup,
      'guardianName': instance.guardianName,
      'parentContact': instance.guardianContact,
      'address': instance.address,
      'enrollmentDate': instance.admissionDate.toIso8601String(),
      'attendancePercentage': instance.attendancePercentage,
      'isActive': instance.isActive,
      'photoUrl': instance.photoUrl,
      'parentIqamaId': instance.parentIqamaId,
      'parentPassportId': instance.parentPassportId,
      'fatherWhatsapp': instance.fatherWhatsapp,
      'motherWhatsapp': instance.motherWhatsapp,
      'country': instance.country,
      'state': instance.state,
      'studentIqamaNumber': instance.studentIqamaNumber,
      'studentIqamaUrl': instance.studentIqamaUrl,
      'fatherOccupation': instance.fatherOccupation,
      'motherOccupation': instance.motherOccupation,
      'numberOfChildren': instance.numberOfChildren,
      'childrenAges': instance.childrenAges,
      'shift': instance.shift,
      'needsTransportation': instance.needsTransportation,
      'transportationFee': instance.transportationFee,
      'hasConcession': instance.hasConcession,
      'instituteId': instance.instituteId,
      'scholarshipAmount': instance.scholarshipAmount,
    };

const _$GenderEnumMap = {Gender.male: 'Male', Gender.female: 'Female'};
