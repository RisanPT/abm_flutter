import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_model.freezed.dart';
part 'permission_model.g.dart';

@freezed
 abstract class PermissionModel with _$PermissionModel {
  const factory PermissionModel({
    required String role,
    @Default([]) List<String> permissions,
    String? instituteId,
  }) = _PermissionModel;

  factory PermissionModel.fromJson(Map<String, dynamic> json) => _$PermissionModelFromJson(json);
}
