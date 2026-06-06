// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventModel _$EventModelFromJson(Map<String, dynamic> json) => _EventModel(
  id: json['_id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  imageUrls: (json['imageUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  date: DateTime.parse(json['date'] as String),
  location: json['location'] as String,
  status:
      $enumDecodeNullable(_$EventStatusEnumMap, json['status']) ??
      EventStatus.upcoming,
);

Map<String, dynamic> _$EventModelToJson(_EventModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'imageUrls': instance.imageUrls,
      'date': instance.date.toIso8601String(),
      'location': instance.location,
      'status': _$EventStatusEnumMap[instance.status]!,
    };

const _$EventStatusEnumMap = {
  EventStatus.upcoming: 'Upcoming',
  EventStatus.completed: 'Completed',
  EventStatus.cancelled: 'Cancelled',
};
