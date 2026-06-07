import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_model.freezed.dart';
part 'student_model.g.dart';

enum Gender {
  @JsonValue('Male')
  male,
  @JsonValue('Female')
  female,
}

@freezed
abstract class StudentModel with _$StudentModel {
  const factory StudentModel({
    @JsonKey(name: '_id') required String id,
    required String fullName,
    @JsonKey(name: 'studentId') required String admissionNumber,
    @JsonKey(name: 'grade') required String classroom,
    required DateTime dateOfBirth,
    required Gender gender,
    String? bloodGroup,
    @Default('Unknown') String guardianName,
    @JsonKey(name: 'parentContact') required String guardianContact,
    required String address,
    @JsonKey(name: 'enrollmentDate') required DateTime admissionDate,
    double? attendancePercentage,
    @Default(true) bool isActive,
    String? photoUrl,
    String? parentPassportId,
    String? parentIqamaId,
    @Default(false) bool needsTransportation,
    @Default(0) double transportationFee,
    @Default(false) bool hasConcession,
    @Default('664c39f00000000000000001') String instituteId,
    double? scholarshipAmount,
  }) = _StudentModel;

  factory StudentModel.fromJson(Map<String, dynamic> json) => _$StudentModelFromJson(json);
}
