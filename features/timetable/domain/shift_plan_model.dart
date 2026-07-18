import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_plan_model.freezed.dart';
part 'shift_plan_model.g.dart';

@freezed
abstract class ShiftPlanModel with _$ShiftPlanModel {
  const factory ShiftPlanModel({
    @JsonKey(name: '_id') String? id,
    required String instituteId,
    required String academicYear,
    required String shift,
    required int year,
    required int month,
    @Default([]) List<DateTime> classDates,
  }) = _ShiftPlanModel;

  factory ShiftPlanModel.fromJson(Map<String, dynamic> json) =>
      _$ShiftPlanModelFromJson(json);
}
