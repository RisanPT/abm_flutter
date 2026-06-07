import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

class AppRoles {
  static const superAdmin = 'Super Admin';
  static const itAdmin = 'IT Admin';
  static const headMaster = 'Head Master';
  static const teacher = 'Teacher';
  static const treasurer = 'Treasurer';
  static const staff = 'Staff';

  static const coreRoles = [superAdmin, itAdmin, headMaster, teacher, treasurer, staff];
}

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String username,
    required String role,
    String? photoUrl,
    String? phoneNumber,
    String? instituteId,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
