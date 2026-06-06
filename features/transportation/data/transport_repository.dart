import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/transportation/domain/transport_models.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transport_repository.g.dart';

@Riverpod(keepAlive: true)
TransportRepository transportRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return TransportRepository(dio);
}

class TransportRepository {
  final Dio _dio;
  TransportRepository(this._dio);

  // ── Vehicles ─────────────────────────────────────────────────────────────

  Future<List<VehicleModel>> getVehicles(String instituteId) async {
    final response = await _dio.get('/transport/vehicles', queryParameters: {'instituteId': instituteId});
    return (response.data as List).map((e) => VehicleModel.fromJson(e)).toList();
  }

  Future<VehicleModel> addVehicle(VehicleModel vehicle) async {
    final data = vehicle.toJson();
    data.remove('_id');
    final response = await _dio.post('/transport/vehicles', data: data);
    return VehicleModel.fromJson(response.data);
  }

  Future<VehicleModel> updateVehicle(VehicleModel vehicle) async {
    final data = vehicle.toJson();
    data.remove('_id');
    final response = await _dio.put('/transport/vehicles/${vehicle.id}', data: data);
    return VehicleModel.fromJson(response.data);
  }

  Future<void> deleteVehicle(String id) async {
    await _dio.delete('/transport/vehicles/$id');
  }

  Future<VehicleModel> assignDriverToVehicle(String vehicleId, String? driverId) async {
    final response = await _dio.patch(
      '/transport/vehicles/$vehicleId/assign-driver',
      data: {'driverId': driverId},
    );
    return VehicleModel.fromJson(response.data);
  }

  // ── Drivers ───────────────────────────────────────────────────────────────

  Future<List<DriverModel>> getDrivers(String instituteId) async {
    final response = await _dio.get('/transport/drivers', queryParameters: {'instituteId': instituteId});
    return (response.data as List).map((e) => DriverModel.fromJson(e)).toList();
  }

  Future<DriverModel> addDriver(DriverModel driver) async {
    final data = driver.toJson();
    data.remove('_id');
    final response = await _dio.post('/transport/drivers', data: data);
    return DriverModel.fromJson(response.data);
  }

  Future<DriverModel> updateDriver(DriverModel driver) async {
    final data = driver.toJson();
    data.remove('_id');
    final response = await _dio.put('/transport/drivers/${driver.id}', data: data);
    return DriverModel.fromJson(response.data);
  }

  Future<void> deleteDriver(String id) async {
    await _dio.delete('/transport/drivers/$id');
  }

  // ── Routes ────────────────────────────────────────────────────────────────

  Future<List<RouteModel>> getRoutes(String instituteId) async {
    final response = await _dio.get('/transport/routes', queryParameters: {'instituteId': instituteId});
    return (response.data as List).map((e) => RouteModel.fromJson(e)).toList();
  }

  Future<RouteModel> addRoute(RouteModel route) async {
    final data = route.toJson();
    data.remove('_id');
    final response = await _dio.post('/transport/routes', data: data);
    return RouteModel.fromJson(response.data);
  }

  Future<RouteModel> updateRoute(RouteModel route) async {
    final data = route.toJson();
    data.remove('_id');
    final response = await _dio.put('/transport/routes/${route.id}', data: data);
    return RouteModel.fromJson(response.data);
  }

  Future<void> deleteRoute(String id) async {
    await _dio.delete('/transport/routes/$id');
  }

  Future<RouteModel> assignVehicleToRoute(String routeId, String? vehicleId) async {
    final response = await _dio.patch(
      '/transport/routes/$routeId/assign-vehicle',
      data: {'vehicleId': vehicleId},
    );
    return RouteModel.fromJson(response.data);
  }

  // ── Assignments ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAssignments({required String instituteId, String? routeId}) async {
    final params = <String, dynamic>{'instituteId': instituteId};
    if (routeId != null) params['routeId'] = routeId;
    final response = await _dio.get('/transport/assignments', queryParameters: params);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> assignStudent({
    required String studentId,
    required String routeId,
    required String instituteId,
  }) async {
    await _dio.post('/transport/assignments', data: {
      'studentId': studentId,
      'routeId': routeId,
      'instituteId': instituteId,
    });
  }

  Future<void> removeStudentFromTransport(String studentId) async {
    await _dio.delete('/transport/assignments/$studentId');
  }

  Future<List<Map<String, dynamic>>> getUnassignedStudents(String instituteId) async {
    final response = await _dio.get(
      '/transport/unassigned-students',
      queryParameters: {'instituteId': instituteId},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
