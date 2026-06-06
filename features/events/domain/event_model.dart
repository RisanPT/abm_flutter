import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

enum EventStatus {
  @JsonValue('Upcoming')
  upcoming,
  @JsonValue('Completed')
  completed,
  @JsonValue('Cancelled')
  cancelled,
}

@freezed
abstract class EventModel with _$EventModel {
  const factory EventModel({
    @JsonKey(name: '_id') String? id,
    required String title,
    String? description,
    List<String>? imageUrls,
    required DateTime date,
    required String location,
    @Default(EventStatus.upcoming) EventStatus status,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);
}
