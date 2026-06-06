import 'package:freezed_annotation/freezed_annotation.dart';

part 'classroom_model.freezed.dart';
part 'classroom_model.g.dart';

@freezed
abstract class ClassroomModel with _$ClassroomModel {
  const factory ClassroomModel({
    @JsonKey(name: '_id') required String id,
    required String name,
    String? description,
    @Default([]) List<String> subjects,
  }) = _ClassroomModel;

  factory ClassroomModel.fromJson(Map<String, dynamic> json) => _$ClassroomModelFromJson(json);
}
