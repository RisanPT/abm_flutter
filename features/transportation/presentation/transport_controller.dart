import 'package:abm_madrasa/features/transportation/data/transport_repository.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/transportation/domain/transport_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transport_controller.g.dart';

// ── Data Providers ────────────────────────────────────────────────────────────

@riverpod
Future<List<VehicleModel>> transportVehicles(Ref ref) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref.watch(transportRepositoryProvider).getVehicles(institute.id);
}

@riverpod
Future<List<DriverModel>> transportDrivers(Ref ref) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref.watch(transportRepositoryProvider).getDrivers(institute.id);
}

@riverpod
Future<List<RouteModel>> transportRoutes(Ref ref) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref.watch(transportRepositoryProvider).getRoutes(institute.id);
}

// Family provider for route-specific assignments
final transportAssignmentsByRouteProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, routeId) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref
      .watch(transportRepositoryProvider)
      .getAssignments(instituteId: institute.id, routeId: routeId);
});

// All assignments (no route filter)
final transportAssignmentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref
      .watch(transportRepositoryProvider)
      .getAssignments(instituteId: institute.id);
});

final unassignedTransportStudentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref
      .watch(transportRepositoryProvider)
      .getUnassignedStudents(institute.id);
});

// ── Fleet Management Controller ───────────────────────────────────────────────

@Riverpod(keepAlive: true)
class FleetManagementController extends _$FleetManagementController {
  @override
  void build() {}

  // Vehicles
  Future<void> addVehicle(VehicleModel vehicle) async {
    await ref.read(transportRepositoryProvider).addVehicle(vehicle);
    ref.invalidate(transportVehiclesProvider);
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    await ref.read(transportRepositoryProvider).updateVehicle(vehicle);
    ref.invalidate(transportVehiclesProvider);
  }

  Future<void> deleteVehicle(String id) async {
    await ref.read(transportRepositoryProvider).deleteVehicle(id);
    ref.invalidate(transportVehiclesProvider);
    ref.invalidate(transportRoutesProvider);
  }

  Future<void> assignDriverToVehicle(String vehicleId, String? driverId) async {
    await ref.read(transportRepositoryProvider).assignDriverToVehicle(vehicleId, driverId);
    ref.invalidate(transportVehiclesProvider);
  }

  // Drivers
  Future<void> addDriver(DriverModel driver) async {
    await ref.read(transportRepositoryProvider).addDriver(driver);
    ref.invalidate(transportDriversProvider);
  }

  Future<void> updateDriver(DriverModel driver) async {
    await ref.read(transportRepositoryProvider).updateDriver(driver);
    ref.invalidate(transportDriversProvider);
  }

  Future<void> deleteDriver(String id) async {
    await ref.read(transportRepositoryProvider).deleteDriver(id);
    ref.invalidate(transportDriversProvider);
    ref.invalidate(transportVehiclesProvider);
  }

  // Routes
  Future<void> addRoute(RouteModel route) async {
    await ref.read(transportRepositoryProvider).addRoute(route);
    ref.invalidate(transportRoutesProvider);
  }

  Future<void> updateRoute(RouteModel route) async {
    await ref.read(transportRepositoryProvider).updateRoute(route);
    ref.invalidate(transportRoutesProvider);
  }

  Future<void> deleteRoute(String id) async {
    await ref.read(transportRepositoryProvider).deleteRoute(id);
    ref.invalidate(transportRoutesProvider);
    ref.invalidate(transportAssignmentsProvider);
    ref.invalidate(unassignedTransportStudentsProvider);
  }

  Future<void> assignVehicleToRoute(String routeId, String? vehicleId) async {
    await ref.read(transportRepositoryProvider).assignVehicleToRoute(routeId, vehicleId);
    ref.invalidate(transportRoutesProvider);
  }

  // Student assignments
  Future<void> assignStudent({
    required String studentId,
    required String routeId,
    required String instituteId,
  }) async {
    await ref.read(transportRepositoryProvider).assignStudent(
      studentId: studentId,
      routeId: routeId,
      instituteId: instituteId,
    );
    ref.invalidate(transportAssignmentsProvider);
    ref.invalidate(unassignedTransportStudentsProvider);
  }

  Future<void> removeStudent(String studentId) async {
    await ref.read(transportRepositoryProvider).removeStudentFromTransport(studentId);
    ref.invalidate(transportAssignmentsProvider);
    ref.invalidate(unassignedTransportStudentsProvider);
  }
}
