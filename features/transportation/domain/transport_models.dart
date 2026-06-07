import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_models.freezed.dart';
part 'transport_models.g.dart';

Object? _readDriverId(Map json, String key) {
  final val = json['driver'];
  if (val is Map) {
    return val['_id'];
  }
  return val;
}

Object? _readVehicleId(Map json, String key) {
  final val = json['assignedVehicle'];
  if (val is Map) {
    return val['_id'];
  }
  return val;
}

@freezed
abstract class VehicleModel with _$VehicleModel {
  const factory VehicleModel({
    @JsonKey(name: '_id') required String id,
    required String plateNumber,
    required String model,
    required int capacity,
    @JsonKey(name: 'driver', readValue: _readDriverId) String? driverId,
    @Default(true) bool isActive,
    required String instituteId,
  }) = _VehicleModel;

  factory VehicleModel.fromJson(Map<String, dynamic> json) => _$VehicleModelFromJson(json);
}

@freezed
abstract class DriverModel with _$DriverModel {
  const factory DriverModel({
    @JsonKey(name: '_id') required String id,
    required String fullName,
    required String phone,
    required String licenseNumber,
    @Default(true) bool isActive,
    required String instituteId,
  }) = _DriverModel;

  factory DriverModel.fromJson(Map<String, dynamic> json) => _$DriverModelFromJson(json);
}

@freezed
abstract class RouteModel with _$RouteModel {
  const factory RouteModel({
    @JsonKey(name: '_id') required String id,
    required String name,
    @Default([]) List<String> pickupPoints,
    @JsonKey(name: 'assignedVehicle', readValue: _readVehicleId) String? assignedVehicleId,
    @Default(true) bool isActive,
    required String instituteId,
  }) = _RouteModel;

  factory RouteModel.fromJson(Map<String, dynamic> json) => _$RouteModelFromJson(json);
}


