import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/dashboard/data/dashboard_service.dart';
import 'package:abm_madrasa/features/dashboard/domain/dashboard_stats_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_controller.g.dart';

@riverpod
class DashboardController extends _$DashboardController {
  @override
  Future<DashboardStats> build() async {
    ref.watch(selectedInstituteProvider);
    return _fetchStats();
  }

  Future<DashboardStats> _fetchStats() async {
    final instituteId = ref.read(selectedInstituteProvider).id;
    final service = ref.read(dashboardServiceProvider);
    return service.getDashboardStats(instituteId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}
