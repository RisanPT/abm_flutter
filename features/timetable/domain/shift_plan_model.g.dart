// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftPlanModel _$ShiftPlanModelFromJson(Map<String, dynamic> json) =>
    _ShiftPlanModel(
      id: json['_id'] as String?,
      instituteId: json['instituteId'] as String,
      shift: json['shift'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      classDates:
          (json['classDates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ShiftPlanModelToJson(
  _ShiftPlanModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'instituteId': instance.instituteId,
  'shift': instance.shift,
  'year': instance.year,
  'month': instance.month,
  'classDates': instance.classDates.map((e) => e.toIso8601String()).toList(),
};
