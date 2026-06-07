import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/transportation/domain/transport_models.dart';
import 'package:abm_madrasa/features/transportation/presentation/transport_controller.dart';
import 'package:dio/dio.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/institute_banner_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FleetManagementScreen extends ConsumerStatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  ConsumerState<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends ConsumerState<FleetManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Fleet & Transport',
            subtitle: 'Manage vehicles, drivers, routes and student assignments',
            showBackButton: false,
            instituteBanner: const InstituteBannerChip(),
            actions: [
              IconButton(
                onPressed: _showAddDialog,
                icon: const Icon(LucideIcons.plus, color: Colors.white),
                tooltip: 'Add',
              ),
            ],
          ),
          Container(
            color: colors.cardBackground,
            child: TabBar(
              controller: _tabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.primary,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Vehicles', icon: Icon(LucideIcons.bus, size: 18)),
                Tab(text: 'Drivers', icon: Icon(LucideIcons.userCheck, size: 18)),
                Tab(text: 'Routes', icon: Icon(LucideIcons.mapPin, size: 18)),
                Tab(text: 'Students', icon: Icon(LucideIcons.users, size: 18)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _VehiclesList(),
                _DriversList(),
                _RoutesList(),
                _StudentAssignmentList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final index = _tabController.index;
    if (index == 0) {
      _showVehicleDialog();
    } else if (index == 1) {
      _showDriverDialog();
    } else if (index == 2) {
      _showRouteDialog();
    } else {
      // Students tab — assignment dialog
      _showAssignStudentDialog();
    }
  }

  // ── Vehicle Dialog ──────────────────────────────────────────────────────────

  void _showVehicleDialog([VehicleModel? existing]) {
    final plateCtrl = TextEditingController(text: existing?.plateNumber ?? '');
    final modelCtrl = TextEditingController(text: existing?.model ?? '');
    final capCtrl = TextEditingController(text: existing == null ? '' : existing.capacity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Plate Number')),
            const Gap(12),
            TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
            const Gap(12),
            TextField(
              controller: capCtrl,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final vehicle = VehicleModel(
                id: existing?.id ?? '',
                plateNumber: plateCtrl.text.trim(),
                model: modelCtrl.text.trim(),
                capacity: int.tryParse(capCtrl.text) ?? 14,
                instituteId: ref.read(selectedInstituteProvider).id,
                isActive: true,
                driverId: existing?.driverId,
              );
              final ctrl = ref.read(fleetManagementControllerProvider.notifier);
              try {
                if (existing == null) {
                  await ctrl.addVehicle(vehicle);
                } else {
                  await ctrl.updateVehicle(vehicle);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  String errMsg = e.toString();
                  if (e is DioException) {
                    final responseData = e.response?.data;
                    if (responseData is Map && responseData['message'] != null) {
                      errMsg = responseData['message'].toString();
                    } else if (e.message != null) {
                      errMsg = e.message!;
                    }
                  }
                  if (errMsg.contains('duplicate key error') || errMsg.contains('E11000')) {
                    errMsg = 'Vehicle with this plate number already exists';
                  }
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(errMsg)),
                  );
                }
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  // ── Driver Dialog ───────────────────────────────────────────────────────────

  void _showDriverDialog([DriverModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final licenseCtrl = TextEditingController(text: existing?.licenseNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Driver' : 'Edit Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const Gap(12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
            const Gap(12),
            TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: 'License Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final driver = DriverModel(
                id: existing?.id ?? '',
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                licenseNumber: licenseCtrl.text.trim(),
                instituteId: ref.read(selectedInstituteProvider).id,
                isActive: true,
              );
              final ctrl = ref.read(fleetManagementControllerProvider.notifier);
              try {
                if (existing == null) {
                  await ctrl.addDriver(driver);
                } else {
                  await ctrl.updateDriver(driver);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  String errMsg = e.toString();
                  if (e is DioException) {
                    final responseData = e.response?.data;
                    if (responseData is Map && responseData['message'] != null) {
                      errMsg = responseData['message'].toString();
                    } else if (e.message != null) {
                      errMsg = e.message!;
                    }
                  }
                  if (errMsg.contains('duplicate key error') || errMsg.contains('E11000')) {
                    errMsg = 'Driver with this license number already exists';
                  }
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(errMsg)),
                  );
                }
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  // ── Route Dialog ────────────────────────────────────────────────────────────

  void _showRouteDialog([RouteModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final pointsCtrl = TextEditingController(text: existing?.pickupPoints.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Route' : 'Edit Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Route Name')),
            const Gap(12),
            TextField(
              controller: pointsCtrl,
              decoration: const InputDecoration(labelText: 'Pickup Points (comma-separated)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final route = RouteModel(
                id: existing?.id ?? '',
                name: nameCtrl.text.trim(),
                pickupPoints: pointsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                instituteId: ref.read(selectedInstituteProvider).id,
                isActive: true,
                assignedVehicleId: existing?.assignedVehicleId,
              );
              final ctrl = ref.read(fleetManagementControllerProvider.notifier);
              try {
                if (existing == null) {
                  await ctrl.addRoute(route);
                } else {
                  await ctrl.updateRoute(route);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  String errMsg = e.toString();
                  if (e is DioException) {
                    final responseData = e.response?.data;
                    if (responseData is Map && responseData['message'] != null) {
                      errMsg = responseData['message'].toString();
                    } else if (e.message != null) {
                      errMsg = e.message!;
                    }
                  }
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(errMsg)),
                  );
                }
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  // ── Assign Student Dialog ───────────────────────────────────────────────────

  void _showAssignStudentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _AssignStudentDialog(),
    );
  }
}

// ── Vehicles List ─────────────────────────────────────────────────────────────

class _VehiclesList extends ConsumerWidget {
  const _VehiclesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(transportVehiclesProvider);
    final driversAsync = ref.watch(transportDriversProvider);
    return vehiclesAsync.when(
      data: (vehicles) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final v = vehicles[index];
          final drivers = driversAsync.when(
            data: (d) => d,
            loading: () => <DriverModel>[],
            error: (_, _) => <DriverModel>[],
          );
          final assignedDriver = drivers.where((d) => d.id == v.driverId).firstOrNull;
          return _TransportCard(
            icon: LucideIcons.bus,
            title: v.plateNumber,
            subtitle: '${v.model} • Capacity: ${v.capacity}',
            badge: assignedDriver != null ? 'Driver: ${assignedDriver.fullName}' : 'No driver assigned',
            badgeColor: assignedDriver != null ? Colors.green : Colors.orange,
            onEdit: () => _showVehicleDialog(context, ref, v),
            onDelete: () => _confirmDelete(
              context,
              'vehicle "${v.plateNumber}"',
              () => ref.read(fleetManagementControllerProvider.notifier).deleteVehicle(v.id),
            ),
            trailing: _AssignDriverButton(vehicle: v, drivers: drivers),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showVehicleDialog(BuildContext context, WidgetRef ref, VehicleModel v) {
    final state = context.findAncestorStateOfType<_FleetManagementScreenState>();
    state?._showVehicleDialog(v);
  }

  void _confirmDelete(BuildContext context, String label, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete $label? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await onConfirm();
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  String errMsg = e.toString();
                  if (e is DioException) {
                    final responseData = e.response?.data;
                    if (responseData is Map && responseData['message'] != null) {
                      errMsg = responseData['message'].toString();
                    }
                  }
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Drivers List ──────────────────────────────────────────────────────────────

class _DriversList extends ConsumerWidget {
  const _DriversList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(transportDriversProvider);
    return driversAsync.when(
      data: (drivers) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final d = drivers[index];
          return _TransportCard(
            icon: LucideIcons.userCheck,
            title: d.fullName,
            subtitle: 'License: ${d.licenseNumber}',
            badge: d.phone,
            badgeColor: context.colors.primary,
            onEdit: () {
              final state = context.findAncestorStateOfType<_FleetManagementScreenState>();
              state?._showDriverDialog(d);
            },
            onDelete: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text('Delete driver "${d.fullName}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      try {
                        await ref.read(fleetManagementControllerProvider.notifier).deleteDriver(d.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          String errMsg = e.toString();
                          if (e is DioException) {
                            final responseData = e.response?.data;
                            if (responseData is Map && responseData['message'] != null) {
                              errMsg = responseData['message'].toString();
                            }
                          }
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                        }
                      }
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Routes List ───────────────────────────────────────────────────────────────

class _RoutesList extends ConsumerWidget {
  const _RoutesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(transportRoutesProvider);
    final vehiclesAsync = ref.watch(transportVehiclesProvider);
    return routesAsync.when(
      data: (routes) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final r = routes[index];
          final vehicles = vehiclesAsync.when(
            data: (v) => v,
            loading: () => <VehicleModel>[],
            error: (_, _) => <VehicleModel>[],
          );
          final assignedVehicle = vehicles.where((v) => v.id == r.assignedVehicleId).firstOrNull;
          return _TransportCard(
            icon: LucideIcons.map,
            title: r.name,
            subtitle: 'Stops: ${r.pickupPoints.join(" → ")}',
            badge: assignedVehicle != null ? 'Bus: ${assignedVehicle.plateNumber}' : 'No vehicle',
            badgeColor: assignedVehicle != null ? Colors.blue : Colors.orange,
            onEdit: () {
              final state = context.findAncestorStateOfType<_FleetManagementScreenState>();
              state?._showRouteDialog(r);
            },
            onDelete: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text('Delete route "${r.name}"? All student assignments will be removed.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      try {
                        await ref.read(fleetManagementControllerProvider.notifier).deleteRoute(r.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          String errMsg = e.toString();
                          if (e is DioException) {
                            final responseData = e.response?.data;
                            if (responseData is Map && responseData['message'] != null) {
                              errMsg = responseData['message'].toString();
                            }
                          }
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                        }
                      }
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            trailing: _AssignVehicleButton(route: r, vehicles: vehicles),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Student Assignments ───────────────────────────────────────────────────────

class _StudentAssignmentList extends ConsumerWidget {
  const _StudentAssignmentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(transportAssignmentsProvider);
    return assignmentsAsync.when(
      data: (assignments) => assignments.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.users, size: 48, color: context.colors.textSecondary.withValues(alpha: 0.3)),
                  const Gap(16),
                  Text('No students assigned to transport', style: context.typography.bodyLarge),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final a = assignments[index];
                final student = a['studentId'] as Map<String, dynamic>?;
                final name = student?['fullName'] as String? ?? 'Unknown';
                final admNo = student?['studentId'] as String? ?? '';
                final grade = student?['grade'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                      child: Text(name.isNotEmpty ? name[0] : 'S',
                          style: TextStyle(color: context.colors.primary)),
                    ),
                    title: Text(name, style: context.typography.bodyMediumSemiBold),
                    subtitle: Text('$admNo • $grade'),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.userMinus, color: Colors.red),
                      tooltip: 'Remove from transport',
                      onPressed: () async {
                        final studentId = student?['_id'] as String?;
                        if (studentId != null) {
                          try {
                            await ref
                                .read(fleetManagementControllerProvider.notifier)
                                .removeStudent(studentId);
                          } catch (e) {
                            if (context.mounted) {
                              String errMsg = e.toString();
                              if (e is DioException) {
                                final responseData = e.response?.data;
                                if (responseData is Map && responseData['message'] != null) {
                                  errMsg = responseData['message'].toString();
                                }
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
                            }
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Assign Driver Button ──────────────────────────────────────────────────────

class _AssignDriverButton extends ConsumerWidget {
  const _AssignDriverButton({required this.vehicle, required this.drivers});
  final VehicleModel vehicle;
  final List<DriverModel> drivers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showAssignDialog(context, ref),
      icon: const Icon(LucideIcons.userCheck, size: 16),
      label: const Text('Assign'),
      style: TextButton.styleFrom(foregroundColor: context.colors.primary),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    String? selectedId = vehicle.driverId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Assign Driver to Vehicle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: selectedId,
                decoration: const InputDecoration(labelText: 'Driver', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.fullName))),
                ],
                onChanged: (v) => setState(() => selectedId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(fleetManagementControllerProvider.notifier)
                      .assignDriverToVehicle(vehicle.id, selectedId);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    String errMsg = e.toString();
                    if (e is DioException) {
                      final responseData = e.response?.data;
                      if (responseData is Map && responseData['message'] != null) {
                        errMsg = responseData['message'].toString();
                      }
                    }
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assign Vehicle Button ─────────────────────────────────────────────────────

class _AssignVehicleButton extends ConsumerWidget {
  const _AssignVehicleButton({required this.route, required this.vehicles});
  final RouteModel route;
  final List<VehicleModel> vehicles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showAssignDialog(context, ref),
      icon: const Icon(LucideIcons.bus, size: 16),
      label: const Text('Assign'),
      style: TextButton.styleFrom(foregroundColor: context.colors.primary),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    String? selectedId = route.assignedVehicleId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Assign Vehicle to Route'),
          content: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: const InputDecoration(labelText: 'Vehicle', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ...vehicles.map((v) => DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.plateNumber} (${v.capacity} seats)'),
                  )),
            ],
            onChanged: (v) => setState(() => selectedId = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(fleetManagementControllerProvider.notifier)
                      .assignVehicleToRoute(route.id, selectedId);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    String errMsg = e.toString();
                    if (e is DioException) {
                      final responseData = e.response?.data;
                      if (responseData is Map && responseData['message'] != null) {
                        errMsg = responseData['message'].toString();
                      }
                    }
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assign Student Dialog ─────────────────────────────────────────────────────

class _AssignStudentDialog extends ConsumerWidget {
  const _AssignStudentDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(unassignedTransportStudentsProvider);
    final routesAsync = ref.watch(transportRoutesProvider);
    String? selectedStudentId;
    String? selectedRouteId;
    String? selectedClass;

    return StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Assign Student to Route'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              studentsAsync.when(
                data: (allStudents) {
                  final classes = allStudents.map((s) => s['grade'] as String? ?? 'Unknown').toSet().toList()..sort();
                  final filteredStudents = selectedClass == null
                      ? allStudents
                      : allStudents.where((s) => (s['grade'] as String? ?? 'Unknown') == selectedClass).toList();
                  
                  if (selectedStudentId != null && !filteredStudents.any((s) => s['_id'] == selectedStudentId)) {
                    selectedStudentId = null;
                  }

                  return Column(
                    children: [
                      DropdownButtonFormField<String?>(
                        initialValue: selectedClass,
                        decoration: const InputDecoration(labelText: 'Filter by Class', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Classes')),
                          ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (v) => setState(() {
                          selectedClass = v;
                          selectedStudentId = null;
                        }),
                      ),
                      const Gap(16),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedStudentId,
                        decoration: const InputDecoration(labelText: 'Student', border: OutlineInputBorder()),
                        items: filteredStudents.map((s) {
                          final id = s['_id'] as String;
                          final name = s['fullName'] as String? ?? 'Unknown';
                          final admNo = s['studentId'] as String? ?? '';
                          return DropdownMenuItem<String?>(value: id, child: Text('$name ($admNo)'));
                        }).toList(),
                        onChanged: (v) => setState(() => selectedStudentId = v),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(16),
              routesAsync.when(
                data: (routes) => DropdownButtonFormField<String>(
                  initialValue: selectedRouteId,
                  decoration: const InputDecoration(labelText: 'Route', border: OutlineInputBorder()),
                  items: routes
                      .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRouteId = v),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: selectedStudentId != null && selectedRouteId != null
                ? () async {
                    try {
                      await ref.read(fleetManagementControllerProvider.notifier).assignStudent(
                        studentId: selectedStudentId!,
                        routeId: selectedRouteId!,
                        instituteId: ref.read(selectedInstituteProvider).id,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        String errMsg = e.toString();
                        if (e is DioException) {
                          final responseData = e.response?.data;
                          if (responseData is Map && responseData['message'] != null) {
                            errMsg = responseData['message'].toString();
                          }
                        }
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                      }
                    }
                  }
                : null,
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}

// ── Shared Card Widget ────────────────────────────────────────────────────────

class _TransportCard extends StatelessWidget {
  const _TransportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onEdit,
    required this.onDelete,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary, size: 22),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: typography.bodyLargeSemiBold),
                    Text(subtitle,
                        style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
