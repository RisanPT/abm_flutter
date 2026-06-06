// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClassroomModel _$ClassroomModelFromJson(Map<String, dynamic> json) =>
    _ClassroomModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      subjects:
          (json['subjects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ClassroomModelToJson(_ClassroomModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'subjects': instance.subjects,
    };
