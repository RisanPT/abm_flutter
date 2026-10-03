import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/transportation/domain/transport_models.dart';
import 'package:abm_madrasa/features/transportation/presentation/transport_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/institute_banner_chip.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Brand colors matching the Madrasa theme
const _madrasaGreen = Color(0xFF1B3D2F);
const _madrasaGold = Color(0xFFB8860B);

extension _AsyncValueExt<T> on AsyncValue<T> {
  T? get valueOrNull => asData?.value;
}

class FleetManagementScreen extends ConsumerStatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  ConsumerState<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends ConsumerState<FleetManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vehiclesAsync = ref.watch(transportVehiclesProvider);
    final driversAsync = ref.watch(transportDriversProvider);
    final routesAsync = ref.watch(transportRoutesProvider);
    final assignmentsAsync = ref.watch(transportAssignmentsProvider);

    final vehicles = vehiclesAsync.valueOrNull ?? [];
    final drivers = driversAsync.valueOrNull ?? [];
    final routes = routesAsync.valueOrNull ?? [];
    final assignments = assignmentsAsync.valueOrNull ?? [];

    // Calculate fleet metrics
    final totalSeats = vehicles.fold<int>(0, (sum, v) => sum + v.capacity);
    final assignedDriversCount = vehicles.where((v) => v.driverId != null && v.driverId!.isNotEmpty).length;
    final totalStops = routes.fold<int>(0, (sum, r) => sum + r.pickupPoints.length);
    final assignedStudentsCount = assignments.length;
    final fleetUtilization = totalSeats > 0 ? ((assignedStudentsCount / totalSeats) * 100).clamp(0, 100).toInt() : 0;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Fleet & Transport',
            subtitle: 'Manage vehicles, drivers, routes and student transit rosters',
            showBackButton: false,
            instituteBanner: const InstituteBannerChip(),
            actions: [
              FilledButton.icon(
                onPressed: _showAddDialogForCurrentTab,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(_getAddButtonLabel()),
                style: FilledButton.styleFrom(
                  backgroundColor: _madrasaGold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Gap(8),
              IconButton(
                onPressed: () {
                  ref.invalidate(transportVehiclesProvider);
                  ref.invalidate(transportDriversProvider);
                  ref.invalidate(transportRoutesProvider);
                  ref.invalidate(transportAssignmentsProvider);
                  ref.invalidate(unassignedTransportStudentsProvider);
                },
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Data',
              ),
            ],
          ),

          // Overview KPI Dashboard Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final isMedium = constraints.maxWidth > 600;

                final cards = [
                  _FleetKpiCard(
                    title: 'Fleet Vehicles',
                    value: '${vehicles.length}',
                    subtext: '$totalSeats total seats',
                    icon: LucideIcons.bus,
                    color: const Color(0xFF059669),
                    badge: '${vehicles.where((v) => v.isActive).length} Active',
                  ),
                  _FleetKpiCard(
                    title: 'Drivers',
                    value: '${drivers.length}',
                    subtext: '$assignedDriversCount on vehicle duty',
                    icon: LucideIcons.userCheck,
                    color: const Color(0xFF2563EB),
                    badge: '${drivers.length - assignedDriversCount} Standby',
                  ),
                  _FleetKpiCard(
                    title: 'Transit Routes',
                    value: '${routes.length}',
                    subtext: '$totalStops stops mapped',
                    icon: LucideIcons.mapPin,
                    color: const Color(0xFF7C3AED),
                    badge: '${routes.where((r) => r.assignedVehicleId != null).length} Assigned',
                  ),
                  _FleetKpiCard(
                    title: 'Transport Students',
                    value: '$assignedStudentsCount',
                    subtext: '$fleetUtilization% capacity utilized',
                    icon: LucideIcons.users,
                    color: const Color(0xFFD97706),
                    badge: '$totalSeats Seats Total',
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const Gap(14),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                } else if (isMedium) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const Gap(12),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          Expanded(child: cards[2]),
                          const Gap(12),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final c in cards) ...[
                          SizedBox(width: 220, child: c),
                          const Gap(12),
                        ],
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // Custom Segmented Navigation Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: colors.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: _madrasaGreen,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _madrasaGreen.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.bus, size: 16),
                      const Gap(8),
                      const Text('Vehicles'),
                      const Gap(6),
                      _TabCounterBadge(count: vehicles.length, isSelected: _currentTabIndex == 0),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.userCheck, size: 16),
                      const Gap(8),
                      const Text('Drivers'),
                      const Gap(6),
                      _TabCounterBadge(count: drivers.length, isSelected: _currentTabIndex == 1),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.mapPin, size: 16),
                      const Gap(8),
                      const Text('Routes'),
                      const Gap(6),
                      _TabCounterBadge(count: routes.length, isSelected: _currentTabIndex == 2),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.users, size: 16),
                      const Gap(8),
                      const Text('Students'),
                      const Gap(6),
                      _TabCounterBadge(count: assignments.length, isSelected: _currentTabIndex == 3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _VehiclesListTab(onAdd: () => _showVehicleDialog()),
                _DriversListTab(onAdd: () => _showDriverDialog()),
                _RoutesListTab(onAdd: () => _showRouteDialog()),
                _StudentAssignmentListTab(onAssign: () => _showAssignStudentDialog()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAddButtonLabel() {
    return switch (_currentTabIndex) {
      0 => 'New Vehicle',
      1 => 'New Driver',
      2 => 'New Route',
      _ => 'Assign Student',
    };
  }

  void _showAddDialogForCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        _showVehicleDialog();
        break;
      case 1:
        _showDriverDialog();
        break;
      case 2:
        _showRouteDialog();
        break;
      default:
        _showAssignStudentDialog();
        break;
    }
  }

  // ── Vehicle Dialog ──────────────────────────────────────────────────────────
  void _showVehicleDialog([VehicleModel? existing]) {
    final plateCtrl = TextEditingController(text: existing?.plateNumber ?? '');
    final modelCtrl = TextEditingController(text: existing?.model ?? '');
    final capCtrl = TextEditingController(text: existing == null ? '14' : existing.capacity.toString());
    String? selectedDriverId = existing?.driverId;
    final drivers = ref.read(transportDriversProvider).valueOrNull ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.bus, color: Color(0xFF059669), size: 20),
              ),
              const Gap(12),
              Text(existing == null ? 'Add Fleet Vehicle' : 'Edit Vehicle',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('License Plate Number *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(6),
                  TextField(
                    controller: plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. ABC 1234 or 5678-KSA',
                      prefixIcon: const Icon(LucideIcons.hash, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const Gap(14),
                  const Text('Vehicle Model / Make *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(6),
                  TextField(
                    controller: modelCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Toyota Coaster 2023 / Hyundai H1',
                      prefixIcon: const Icon(LucideIcons.gauge, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const Gap(14),
                  const Text('Seating Capacity *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(6),
                  TextField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 14, 25, 30',
                      prefixIcon: const Icon(LucideIcons.users, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    children: [14, 22, 30, 50].map((preset) {
                      return ActionChip(
                        label: Text('$preset seats'),
                        onPressed: () {
                          setDialogState(() => capCtrl.text = preset.toString());
                        },
                      );
                    }).toList(),
                  ),
                  const Gap(14),
                  const Text('Assign Default Driver (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(6),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedDriverId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Driver Assigned (Standby)')),
                      ...drivers.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.fullName} (${d.phone})'))),
                    ],
                    onChanged: (v) => setDialogState(() => selectedDriverId = v),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _madrasaGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final plate = plateCtrl.text.trim();
                final model = modelCtrl.text.trim();
                final capacity = int.tryParse(capCtrl.text.trim()) ?? 14;

                if (plate.isEmpty || model.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter license plate and model')),
                  );
                  return;
                }

                final vehicle = VehicleModel(
                  id: existing?.id ?? '',
                  plateNumber: plate,
                  model: model,
                  capacity: capacity,
                  instituteId: ref.read(selectedInstituteProvider).id,
                  isActive: true,
                  driverId: selectedDriverId,
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
                    String errMsg = friendlyErrorMessage(e);
                    if (e is DioException) {
                      final responseData = e.response?.data;
                      if (responseData is Map && responseData['message'] != null) {
                        errMsg = responseData['message'].toString();
                      }
                    }
                    if (errMsg.contains('duplicate key error') || errMsg.contains('E11000')) {
                      errMsg = 'A vehicle with this plate number already exists';
                    }
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                  }
                }
              },
              child: Text(existing == null ? 'Add Vehicle' : 'Save Changes'),
            ),
          ],
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.userCheck, color: Color(0xFF2563EB), size: 20),
            ),
            const Gap(12),
            Text(existing == null ? 'Register New Driver' : 'Edit Driver Profile',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Driver Full Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Gap(6),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Tariq Al-Ghamdi',
                  prefixIcon: const Icon(LucideIcons.user, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const Gap(14),
              const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Gap(6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g. +966 50 123 4567',
                  prefixIcon: const Icon(LucideIcons.phone, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const Gap(14),
              const Text('Driving License Number *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Gap(6),
              TextField(
                controller: licenseCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. DL-884920-KSA',
                  prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _madrasaGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              final license = licenseCtrl.text.trim();

              if (name.isEmpty || phone.isEmpty || license.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please fill all driver details')),
                );
                return;
              }

              final driver = DriverModel(
                id: existing?.id ?? '',
                fullName: name,
                phone: phone,
                licenseNumber: license,
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
                  String errMsg = friendlyErrorMessage(e);
                  if (e is DioException) {
                    final responseData = e.response?.data;
                    if (responseData is Map && responseData['message'] != null) {
                      errMsg = responseData['message'].toString();
                    }
                  }
                  if (errMsg.contains('duplicate key error') || errMsg.contains('E11000')) {
                    errMsg = 'A driver with this license number already exists';
                  }
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                }
              }
            },
            child: Text(existing == null ? 'Register Driver' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  // ── Route Dialog ────────────────────────────────────────────────────────────
  void _showRouteDialog([RouteModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final newStopCtrl = TextEditingController();
    final stops = List<String>.from(existing?.pickupPoints ?? []);
    String? selectedVehicleId = existing?.assignedVehicleId;
    final vehicles = ref.read(transportVehiclesProvider).valueOrNull ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.mapPin, color: Color(0xFF7C3AED), size: 20),
              ),
              const Gap(12),
              Text(existing == null ? 'Create Transit Route' : 'Edit Transit Route',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Al-Malaz & Al-Sulaimaniyah Express',
                      prefixIcon: const Icon(LucideIcons.navigation, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const Gap(14),
                  const Text('Assign Vehicle (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(6),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedVehicleId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.bus, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Vehicle Assigned')),
                      ...vehicles.map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.plateNumber} · ${v.model} (${v.capacity} seats)'),
                          )),
                    ],
                    onChanged: (v) => setDialogState(() => selectedVehicleId = v),
                  ),
                  const Gap(14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pickup Stops & Stations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${stops.length} stops', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const Gap(6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newStopCtrl,
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setDialogState(() {
                                stops.add(val.trim());
                                newStopCtrl.clear();
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Add a pickup stop...',
                            prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const Gap(8),
                      IconButton.filledTonal(
                        onPressed: () {
                          if (newStopCtrl.text.trim().isNotEmpty) {
                            setDialogState(() {
                              stops.add(newStopCtrl.text.trim());
                              newStopCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(LucideIcons.plus, size: 18),
                      ),
                    ],
                  ),
                  const Gap(10),
                  if (stops.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: const Text('No stops added yet. Type a stop name above and tap + to add.',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: stops.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value;
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: _madrasaGreen.withValues(alpha: 0.15),
                            radius: 10,
                            child: Text('${index + 1}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _madrasaGreen)),
                          ),
                          label: Text(stop, style: const TextStyle(fontSize: 12)),
                          onDeleted: () {
                            setDialogState(() => stops.removeAt(index));
                          },
                          deleteIcon: const Icon(LucideIcons.x, size: 14),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Colors.grey.shade300),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _madrasaGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a route name')),
                  );
                  return;
                }

                final route = RouteModel(
                  id: existing?.id ?? '',
                  name: name,
                  pickupPoints: stops,
                  instituteId: ref.read(selectedInstituteProvider).id,
                  isActive: true,
                  assignedVehicleId: selectedVehicleId,
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
                    String errMsg = friendlyErrorMessage(e);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg)));
                  }
                }
              },
              child: Text(existing == null ? 'Create Route' : 'Save Changes'),
            ),
          ],
        ),
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

// ── Tab 1: Vehicles List & Cards ──────────────────────────────────────────────
class _VehiclesListTab extends ConsumerStatefulWidget {
  const _VehiclesListTab({required this.onAdd});
  final VoidCallback onAdd;

  @override
  ConsumerState<_VehiclesListTab> createState() => _VehiclesListTabState();
}

class _VehiclesListTabState extends ConsumerState<_VehiclesListTab> {
  String _search = '';
  String _filter = 'All'; // 'All', 'Assigned', 'Unassigned'

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(transportVehiclesProvider);
    final driversAsync = ref.watch(transportDriversProvider);
    final routesAsync = ref.watch(transportRoutesProvider);
    final assignmentsAsync = ref.watch(transportAssignmentsProvider);

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return _FleetEmptyState(
            icon: LucideIcons.bus,
            title: 'No vehicles in the fleet yet',
            subtitle: 'Register your madrasa buses, vans, and contracted transport vehicles.',
            actionLabel: 'Add First Vehicle',
            onAction: widget.onAdd,
          );
        }

        final drivers = driversAsync.valueOrNull ?? [];
        final routes = routesAsync.valueOrNull ?? [];
        final assignments = assignmentsAsync.valueOrNull ?? [];

        final filtered = vehicles.where((v) {
          final matchesSearch = _search.isEmpty ||
              v.plateNumber.toLowerCase().contains(_search.toLowerCase()) ||
              v.model.toLowerCase().contains(_search.toLowerCase());
          final hasDriver = v.driverId != null && v.driverId!.isNotEmpty;
          final matchesFilter = switch (_filter) {
            'Assigned' => hasDriver,
            'Unassigned' => !hasDriver,
            _ => true,
          };
          return matchesSearch && matchesFilter;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // Filter and Search Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by plate number or model...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const Gap(12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Assigned', label: Text('With Driver')),
                    ButtonSegment(value: 'Unassigned', label: Text('No Driver')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (set) => setState(() => _filter = set.first),
                ),
              ],
            ),
            const Gap(16),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No vehicles match your search filter', style: TextStyle(color: context.colors.textSecondary)),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: filtered.map((v) {
                        return SizedBox(
                          width: (constraints.maxWidth - 16) / 2,
                          child: _buildVehicleCard(context, ref, v, drivers, routes, assignments),
                        );
                      }).toList(),
                    );
                  }
                  return Column(
                    children: filtered.map((v) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildVehicleCard(context, ref, v, drivers, routes, assignments),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    WidgetRef ref,
    VehicleModel v,
    List<DriverModel> drivers,
    List<RouteModel> routes,
    List<Map<String, dynamic>> assignments,
  ) {
    final assignedDriver = drivers.where((d) => d.id == v.driverId).firstOrNull;
    final assignedRoute = routes.where((r) => r.assignedVehicleId == v.id).firstOrNull;

    // Count students assigned to the route using this vehicle
    int studentCount = 0;
    if (assignedRoute != null) {
      studentCount = assignments.where((a) {
        final rId = (a['routeId'] is Map ? a['routeId']['_id'] : a['routeId'])?.toString();
        return rId == assignedRoute.id;
      }).length;
    }

    final occupancyRate = v.capacity > 0 ? (studentCount / v.capacity).clamp(0.0, 1.0) : 0.0;
    final isFull = studentCount >= v.capacity && v.capacity > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Plate badge + Model + Options
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Styled Saudi plate badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.bus, size: 14, color: _madrasaGreen),
                    const Gap(6),
                    Text(
                      v.plateNumber.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.model, style: context.typography.bodyLargeSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${v.capacity} passenger seats', style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 18),
                onSelected: (action) {
                  if (action == 'edit') {
                    final parent = context.findAncestorStateOfType<_FleetManagementScreenState>();
                    parent?._showVehicleDialog(v);
                  } else if (action == 'assign') {
                    _showAssignDriverDialog(context, ref, v, drivers);
                  } else if (action == 'delete') {
                    _confirmDeleteVehicle(context, ref, v);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'assign', child: Text('Assign Driver')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit Vehicle')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),

          const Gap(14),
          const Divider(height: 1),
          const Gap(12),

          // Driver & Route Status Rows
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: assignedDriver != null ? const Color(0xFF2563EB).withValues(alpha: 0.12) : Colors.grey[200],
                      child: Icon(
                        assignedDriver != null ? LucideIcons.userCheck : LucideIcons.userX,
                        size: 14,
                        color: assignedDriver != null ? const Color(0xFF2563EB) : Colors.grey,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned Driver', style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
                          Text(
                            assignedDriver?.fullName ?? 'No driver assigned',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: assignedDriver != null ? Colors.black87 : Colors.orange[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAssignDriverDialog(context, ref, v, drivers),
                icon: const Icon(LucideIcons.userCheck, size: 13),
                label: Text(assignedDriver == null ? 'Assign' : 'Change', style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),

          const Gap(10),

          // Route info and Occupancy progress
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF7C3AED)),
                        const Gap(6),
                        Text(
                          assignedRoute != null ? assignedRoute.name : 'Not assigned to route',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: assignedRoute != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFull ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$studentCount / ${v.capacity} Seats',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isFull ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: occupancyRate,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFull ? const Color(0xFFEF4444) : (occupancyRate > 0.8 ? Colors.amber : _madrasaGreen),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDriverDialog(BuildContext context, WidgetRef ref, VehicleModel vehicle, List<DriverModel> drivers) {
    String? selectedId = vehicle.driverId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Assign Driver to ${vehicle.plateNumber}'),
          content: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: InputDecoration(
              labelText: 'Select Driver',
              prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('No Driver (Unassign)')),
              ...drivers.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.fullName} (${d.phone})'))),
            ],
            onChanged: (v) => setDialogState(() => selectedId = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _madrasaGreen),
              onPressed: () async {
                try {
                  await ref.read(fleetManagementControllerProvider.notifier).assignDriverToVehicle(vehicle.id, selectedId);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
                  }
                }
              },
              child: const Text('Save Driver Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteVehicle(BuildContext context, WidgetRef ref, VehicleModel v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Vehicle?'),
        content: Text('Are you sure you want to delete vehicle "${v.plateNumber}" (${v.model})? Routes using this vehicle will become unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(fleetManagementControllerProvider.notifier).deleteVehicle(v.id);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
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

// ── Tab 2: Drivers List & Profiles ────────────────────────────────────────────
class _DriversListTab extends ConsumerStatefulWidget {
  const _DriversListTab({required this.onAdd});
  final VoidCallback onAdd;

  @override
  ConsumerState<_DriversListTab> createState() => _DriversListTabState();
}

class _DriversListTabState extends ConsumerState<_DriversListTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(transportDriversProvider);
    final vehiclesAsync = ref.watch(transportVehiclesProvider);

    return driversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
      data: (drivers) {
        if (drivers.isEmpty) {
          return _FleetEmptyState(
            icon: LucideIcons.userCheck,
            title: 'No registered drivers yet',
            subtitle: 'Add drivers with valid licensing and contact info to assign them to your fleet.',
            actionLabel: 'Register First Driver',
            onAction: widget.onAdd,
          );
        }

        final vehicles = vehiclesAsync.valueOrNull ?? [];
        final filtered = drivers.where((d) {
          return _search.isEmpty ||
              d.fullName.toLowerCase().contains(_search.toLowerCase()) ||
              d.phone.toLowerCase().contains(_search.toLowerCase()) ||
              d.licenseNumber.toLowerCase().contains(_search.toLowerCase());
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            TextField(
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search drivers by name, phone, or license number...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const Gap(16),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No drivers match your search', style: TextStyle(color: context.colors.textSecondary)),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: filtered.map((d) {
                        return SizedBox(
                          width: (constraints.maxWidth - 16) / 2,
                          child: _buildDriverCard(context, ref, d, vehicles),
                        );
                      }).toList(),
                    );
                  }
                  return Column(
                    children: filtered.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildDriverCard(context, ref, d, vehicles),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDriverCard(BuildContext context, WidgetRef ref, DriverModel d, List<VehicleModel> vehicles) {
    final assignedVehicle = vehicles.where((v) => v.driverId == d.id).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                child: Text(
                  d.fullName.isNotEmpty ? d.fullName[0].toUpperCase() : 'D',
                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.fullName, style: context.typography.bodyLargeSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Gap(2),
                    Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 13, color: Colors.grey),
                        const Gap(4),
                        Text('License: ${d.licenseNumber}', style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 18),
                onSelected: (action) {
                  if (action == 'edit') {
                    final parent = context.findAncestorStateOfType<_FleetManagementScreenState>();
                    parent?._showDriverDialog(d);
                  } else if (action == 'delete') {
                    _confirmDeleteDriver(context, ref, d);
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),

          const Gap(12),
          const Divider(height: 1),
          const Gap(12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Phone with copy button
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: d.phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone ${d.phone} copied to clipboard')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 14, color: _madrasaGreen),
                      const Gap(6),
                      Text(d.phone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _madrasaGreen)),
                      const Gap(4),
                      const Icon(LucideIcons.copy, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // Duty status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: assignedVehicle != null ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      assignedVehicle != null ? LucideIcons.bus : LucideIcons.coffee,
                      size: 12,
                      color: assignedVehicle != null ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                    const Gap(6),
                    Text(
                      assignedVehicle != null ? 'Bus: ${assignedVehicle.plateNumber}' : 'Standby Driver',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: assignedVehicle != null ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDriver(BuildContext context, WidgetRef ref, DriverModel d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Driver?'),
        content: Text('Delete driver "${d.fullName}"? Any vehicle currently driven by this driver will be unassigned.'),
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
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
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

// ── Tab 3: Routes List & Stops ────────────────────────────────────────────────
class _RoutesListTab extends ConsumerStatefulWidget {
  const _RoutesListTab({required this.onAdd});
  final VoidCallback onAdd;

  @override
  ConsumerState<_RoutesListTab> createState() => _RoutesListTabState();
}

class _RoutesListTabState extends ConsumerState<_RoutesListTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(transportRoutesProvider);
    final vehiclesAsync = ref.watch(transportVehiclesProvider);
    final driversAsync = ref.watch(transportDriversProvider);
    final assignmentsAsync = ref.watch(transportAssignmentsProvider);

    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
      data: (routes) {
        if (routes.isEmpty) {
          return _FleetEmptyState(
            icon: LucideIcons.mapPin,
            title: 'No routes created yet',
            subtitle: 'Map out pickup points, neighborhoods, and assign buses to regular student routes.',
            actionLabel: 'Create First Route',
            onAction: widget.onAdd,
          );
        }

        final vehicles = vehiclesAsync.valueOrNull ?? [];
        final drivers = driversAsync.valueOrNull ?? [];
        final assignments = assignmentsAsync.valueOrNull ?? [];

        final filtered = routes.where((r) {
          return _search.isEmpty ||
              r.name.toLowerCase().contains(_search.toLowerCase()) ||
              r.pickupPoints.any((p) => p.toLowerCase().contains(_search.toLowerCase()));
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            TextField(
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search routes or pickup stations...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const Gap(16),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No routes match your search', style: TextStyle(color: context.colors.textSecondary)),
                ),
              )
            else
              Column(
                children: filtered.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildRouteCard(context, ref, r, vehicles, drivers, assignments),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRouteCard(
    BuildContext context,
    WidgetRef ref,
    RouteModel r,
    List<VehicleModel> vehicles,
    List<DriverModel> drivers,
    List<Map<String, dynamic>> assignments,
  ) {
    final assignedVehicle = vehicles.where((v) => v.id == r.assignedVehicleId).firstOrNull;
    final assignedDriver = assignedVehicle != null
        ? drivers.where((d) => d.id == assignedVehicle.driverId).firstOrNull
        : null;

    final studentCount = assignments.where((a) {
      final rId = (a['routeId'] is Map ? a['routeId']['_id'] : a['routeId'])?.toString();
      return rId == r.id;
    }).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.navigation, color: Color(0xFF7C3AED), size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: context.typography.bodyLargeSemiBold),
                    Text('${r.pickupPoints.length} pickup points registered',
                        style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
              ),
              // Student count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _madrasaGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.users, size: 14, color: _madrasaGreen),
                    const Gap(6),
                    Text('$studentCount Students',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _madrasaGreen)),
                  ],
                ),
              ),
              const Gap(8),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 18),
                onSelected: (action) {
                  if (action == 'edit') {
                    final parent = context.findAncestorStateOfType<_FleetManagementScreenState>();
                    parent?._showRouteDialog(r);
                  } else if (action == 'assign') {
                    _showAssignVehicleDialog(context, ref, r, vehicles);
                  } else if (action == 'delete') {
                    _confirmDeleteRoute(context, ref, r);
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'assign', child: Text('Assign Vehicle')),
                  PopupMenuItem(value: 'edit', child: Text('Edit Route')),
                  PopupMenuItem(value: 'delete', child: Text('Delete Route', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),

          const Gap(14),

          // Vehicle & Driver Info Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bus, size: 16, color: Color(0xFF2563EB)),
                const Gap(8),
                Expanded(
                  child: Text(
                    assignedVehicle != null
                        ? '${assignedVehicle.plateNumber} (${assignedVehicle.model}) · Driver: ${assignedDriver?.fullName ?? "Unassigned"}'
                        : 'No bus assigned to this route',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: assignedVehicle != null ? Colors.black87 : Colors.orange[800],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAssignVehicleDialog(context, ref, r, vehicles),
                  icon: const Icon(LucideIcons.bus, size: 13),
                  label: Text(assignedVehicle == null ? 'Assign Bus' : 'Change', style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),

          const Gap(12),

          // Pickup points timeline / chips
          if (r.pickupPoints.isNotEmpty) ...[
            const Text('Pickup Stations Sequence:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Gap(6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < r.pickupPoints.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          child: Text('${i + 1}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                        ),
                        const Gap(6),
                        Text(r.pickupPoints[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  if (i < r.pickupPoints.length - 1)
                    const Icon(LucideIcons.arrowRight, size: 12, color: Colors.grey),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignVehicleDialog(BuildContext context, WidgetRef ref, RouteModel route, List<VehicleModel> vehicles) {
    String? selectedId = route.assignedVehicleId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Assign Bus to ${route.name}'),
          content: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: InputDecoration(
              labelText: 'Select Vehicle',
              prefixIcon: const Icon(LucideIcons.bus, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('No Vehicle (Unassigned)')),
              ...vehicles.map((v) => DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.plateNumber} · ${v.model} (${v.capacity} seats)'),
                  )),
            ],
            onChanged: (v) => setDialogState(() => selectedId = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _madrasaGreen),
              onPressed: () async {
                try {
                  await ref.read(fleetManagementControllerProvider.notifier).assignVehicleToRoute(route.id, selectedId);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
                  }
                }
              },
              child: const Text('Save Vehicle Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRoute(BuildContext context, WidgetRef ref, RouteModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Route?'),
        content: Text('Delete route "${r.name}"? All student transit assignments under this route will be removed.'),
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
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
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

// ── Tab 4: Student Transport Roster ───────────────────────────────────────────
class _StudentAssignmentListTab extends ConsumerStatefulWidget {
  const _StudentAssignmentListTab({required this.onAssign});
  final VoidCallback onAssign;

  @override
  ConsumerState<_StudentAssignmentListTab> createState() => _StudentAssignmentListTabState();
}

class _StudentAssignmentListTabState extends ConsumerState<_StudentAssignmentListTab> {
  String _search = '';
  String? _selectedRouteId;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(transportAssignmentsProvider);
    final routesAsync = ref.watch(transportRoutesProvider);

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
      data: (assignments) {
        if (assignments.isEmpty) {
          return _FleetEmptyState(
            icon: LucideIcons.users,
            title: 'No students assigned to transport',
            subtitle: 'Assign registered students who requested transportation to designated routes.',
            actionLabel: 'Assign Student to Route',
            onAction: widget.onAssign,
          );
        }

        final routes = routesAsync.valueOrNull ?? [];

        final filtered = assignments.where((a) {
          final student = a['studentId'] as Map<String, dynamic>?;
          final name = student?['fullName'] as String? ?? '';
          final admNo = student?['studentId'] as String? ?? '';
          final grade = student?['grade'] as String? ?? '';
          final rId = (a['routeId'] is Map ? a['routeId']['_id'] : a['routeId'])?.toString();

          final matchesSearch = _search.isEmpty ||
              name.toLowerCase().contains(_search.toLowerCase()) ||
              admNo.toLowerCase().contains(_search.toLowerCase()) ||
              grade.toLowerCase().contains(_search.toLowerCase());
          final matchesRoute = _selectedRouteId == null || rId == _selectedRouteId;

          return matchesSearch && matchesRoute;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // Filter Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by student name, admission number, or grade...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const Gap(12),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedRouteId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Routes')),
                      ...routes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _selectedRouteId = v),
                  ),
                ),
              ],
            ),
            const Gap(16),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No students match your filter criteria', style: TextStyle(color: context.colors.textSecondary)),
                ),
              )
            else
              Column(
                children: filtered.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildStudentRow(context, ref, a, routes),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStudentRow(BuildContext context, WidgetRef ref, Map<String, dynamic> a, List<RouteModel> routes) {
    final student = a['studentId'] as Map<String, dynamic>?;
    final name = student?['fullName'] as String? ?? 'Unknown Student';
    final admNo = student?['studentId'] as String? ?? '';
    final grade = student?['grade'] as String? ?? '';
    final studentId = student?['_id'] as String?;

    // Route resolution
    final routeData = a['routeId'];
    String routeName = 'Unassigned Route';
    String? busPlate;

    if (routeData is Map) {
      routeName = routeData['name'] as String? ?? 'Route';
      final vData = routeData['assignedVehicle'];
      if (vData is Map) {
        busPlate = vData['plateNumber'] as String?;
      }
    } else if (routeData != null) {
      final rModel = routes.where((r) => r.id == routeData.toString()).firstOrNull;
      if (rModel != null) routeName = rModel.name;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _madrasaGreen.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(color: _madrasaGreen, fontWeight: FontWeight.bold),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.typography.bodyMediumSemiBold),
                const Gap(2),
                Row(
                  children: [
                    if (admNo.isNotEmpty) ...[
                      Text('Adm: $admNo', style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                      const Text(' · ', style: TextStyle(color: Colors.grey)),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(grade.isNotEmpty ? grade : 'Grade N/A',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Route and bus info badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF7C3AED)),
                    const Gap(4),
                    Text(routeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                  ],
                ),
              ),
              if (busPlate != null) ...[
                const Gap(3),
                Text('Bus: $busPlate', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ],
          ),
          const Gap(10),
          IconButton(
            icon: const Icon(LucideIcons.userMinus, color: Colors.red, size: 18),
            tooltip: 'Remove from transport',
            onPressed: () {
              if (studentId != null) {
                _confirmRemoveStudent(context, ref, studentId, name);
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmRemoveStudent(BuildContext context, WidgetRef ref, String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Student from Transport?'),
        content: Text('Remove "$studentName" from their assigned transport route?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(fleetManagementControllerProvider.notifier).removeStudent(studentId);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Shared Assign Student Dialog ──────────────────────────────────────────────
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _madrasaGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.userPlus, color: _madrasaGreen, size: 20),
            ),
            const Gap(12),
            const Text('Assign Student to Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Filter & Select Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Gap(8),
              studentsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                error: (e, _) => Text(friendlyErrorMessage(e)),
                data: (allStudents) {
                  if (allStudents.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.info, color: Colors.amber, size: 18),
                          Gap(10),
                          Expanded(
                            child: Text(
                              'All students who requested transportation have already been assigned to routes.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

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
                        decoration: InputDecoration(
                          labelText: 'Filter by Class/Grade',
                          prefixIcon: const Icon(LucideIcons.filter, size: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Enrolled Classes')),
                          ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (v) => setState(() {
                          selectedClass = v;
                          selectedStudentId = null;
                        }),
                      ),
                      const Gap(10),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedStudentId,
                        decoration: InputDecoration(
                          labelText: 'Select Student *',
                          prefixIcon: const Icon(LucideIcons.user, size: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: filteredStudents.map((s) {
                          final id = s['_id'] as String;
                          final name = s['fullName'] as String? ?? 'Unknown';
                          final admNo = s['studentId'] as String? ?? '';
                          final grade = s['grade'] as String? ?? '';
                          return DropdownMenuItem<String?>(
                            value: id,
                            child: Text('$name · $admNo ($grade)', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => selectedStudentId = v),
                      ),
                    ],
                  );
                },
              ),
              const Gap(16),
              const Text('2. Select Destination Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Gap(8),
              routesAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                error: (e, _) => Text(friendlyErrorMessage(e)),
                data: (routes) {
                  if (routes.isEmpty) {
                    return const Text('No routes created yet. Create a route first.', style: TextStyle(color: Colors.red));
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: selectedRouteId,
                    decoration: InputDecoration(
                      labelText: 'Transit Route *',
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: routes.map((r) {
                      return DropdownMenuItem(value: r.id, child: Text('${r.name} (${r.pickupPoints.length} stops)'));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedRouteId = v),
                  );
                },
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _madrasaGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
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
                        String errMsg = friendlyErrorMessage(e);
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
            child: const Text('Confirm Assignment'),
          ),
        ],
      ),
    );
  }
}

// ── UI Helpers & Subwidgets ───────────────────────────────────────────────────

class _FleetKpiCard extends StatelessWidget {
  const _FleetKpiCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.badge,
  });

  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Gap(8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
          const Gap(2),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
          const Gap(1),
          Text(subtext, style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}

class _TabCounterBadge extends StatelessWidget {
  const _TabCounterBadge({required this.count, required this.isSelected});
  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }
}

class _FleetEmptyState extends StatelessWidget {
  const _FleetEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _madrasaGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: _madrasaGreen),
            ),
            const Gap(12),
            Text(title, style: context.typography.bodyLargeSemiBold.copyWith(fontSize: 16), textAlign: TextAlign.center),
            const Gap(6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary),
              ),
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.plus, size: 15),
              label: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: _madrasaGreen,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
