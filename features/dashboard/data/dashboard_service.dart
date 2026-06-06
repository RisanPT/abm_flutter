import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/dashboard/domain/dashboard_stats_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardService(dio);
});

class DashboardService {
  final Dio _dio;

  DashboardService(this._dio);

  Future<DashboardStats> getDashboardStats() async {
    final response = await _dio.get('/dashboard');
    return DashboardStats.fromJson(response.data);
  }
}
