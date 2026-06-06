import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats_model.freezed.dart';
part 'dashboard_stats_model.g.dart';

@freezed
abstract class MonthlyFinanceData with _$MonthlyFinanceData {
  const factory MonthlyFinanceData({
    required String month,
    required double revenue,
  }) = _MonthlyFinanceData;

  factory MonthlyFinanceData.fromJson(Map<String, dynamic> json) => _$MonthlyFinanceDataFromJson(json);
}

@freezed
abstract class RecentActivity with _$RecentActivity {
  const factory RecentActivity({
    required String type, 
    required String title,
    required String subtitle,
    required DateTime time,
  }) = _RecentActivity;

  factory RecentActivity.fromJson(Map<String, dynamic> json) => _$RecentActivityFromJson(json);
}

@freezed
abstract class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    @Default(0) int totalStudents,
    @Default(0.0) double attendanceRate,
    @Default(0.0) double feeCollectedThisMonth,
    @Default('') String feeCollectedTrend,
    @Default(0) int upcomingEvents,
    @Default([]) List<MonthlyFinanceData> monthlyFinanceData,
    @Default([]) List<RecentActivity> recentActivities,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);
}
