// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) =>
    _VehicleModel(
      id: json['_id'] as String,
      plateNumber: json['plateNumber'] as String,
      model: json['model'] as String,
      capacity: (json['capacity'] as num).toInt(),
      driverId: json['driverId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      instituteId: json['instituteId'] as String,
    );

Map<String, dynamic> _$VehicleModelToJson(_VehicleModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'plateNumber': instance.plateNumber,
      'model': instance.model,
      'capacity': instance.capacity,
      'driverId': instance.driverId,
      'isActive': instance.isActive,
      'instituteId': instance.instituteId,
    };

_DriverModel _$DriverModelFromJson(Map<String, dynamic> json) => _DriverModel(
  id: json['_id'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String,
  licenseNumber: json['licenseNumber'] as String,
  isActive: json['isActive'] as bool? ?? true,
  instituteId: json['instituteId'] as String,
);

Map<String, dynamic> _$DriverModelToJson(_DriverModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'fullName': instance.fullName,
      'phone': instance.phone,
      'licenseNumber': instance.licenseNumber,
      'isActive': instance.isActive,
      'instituteId': instance.instituteId,
    };

_RouteModel _$RouteModelFromJson(Map<String, dynamic> json) => _RouteModel(
  id: json['_id'] as String,
  name: json['name'] as String,
  pickupPoints:
      (json['pickupPoints'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  assignedVehicleId: json['assignedVehicleId'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  instituteId: json['instituteId'] as String,
);

Map<String, dynamic> _$RouteModelToJson(_RouteModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'pickupPoints': instance.pickupPoints,
      'assignedVehicleId': instance.assignedVehicleId,
      'isActive': instance.isActive,
      'instituteId': instance.instituteId,
    };
