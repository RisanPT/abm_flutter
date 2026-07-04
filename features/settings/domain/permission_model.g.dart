// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PermissionModel _$PermissionModelFromJson(Map<String, dynamic> json) =>
    _PermissionModel(
      role: json['role'] as String,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      instituteId: json['instituteId'] as String?,
    );

Map<String, dynamic> _$PermissionModelToJson(_PermissionModel instance) =>
    <String, dynamic>{
      'role': instance.role,
      'permissions': instance.permissions,
      'instituteId': instance.instituteId,
    };
