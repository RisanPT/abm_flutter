// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MonthlyFinanceData _$MonthlyFinanceDataFromJson(Map<String, dynamic> json) =>
    _MonthlyFinanceData(
      month: json['month'] as String,
      revenue: (json['revenue'] as num).toDouble(),
    );

Map<String, dynamic> _$MonthlyFinanceDataToJson(_MonthlyFinanceData instance) =>
    <String, dynamic>{'month': instance.month, 'revenue': instance.revenue};

_RecentActivity _$RecentActivityFromJson(Map<String, dynamic> json) =>
    _RecentActivity(
      type: json['type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      time: DateTime.parse(json['time'] as String),
    );

Map<String, dynamic> _$RecentActivityToJson(_RecentActivity instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'time': instance.time.toIso8601String(),
    };

_DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    _DashboardStats(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      feeCollectedThisMonth:
          (json['feeCollectedThisMonth'] as num?)?.toDouble() ?? 0.0,
      feeCollectedTrend: json['feeCollectedTrend'] as String? ?? '',
      upcomingEvents: (json['upcomingEvents'] as num?)?.toInt() ?? 0,
      monthlyFinanceData:
          (json['monthlyFinanceData'] as List<dynamic>?)
              ?.map(
                (e) => MonthlyFinanceData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      recentActivities:
          (json['recentActivities'] as List<dynamic>?)
              ?.map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DashboardStatsToJson(_DashboardStats instance) =>
    <String, dynamic>{
      'totalStudents': instance.totalStudents,
      'attendanceRate': instance.attendanceRate,
      'feeCollectedThisMonth': instance.feeCollectedThisMonth,
      'feeCollectedTrend': instance.feeCollectedTrend,
      'upcomingEvents': instance.upcomingEvents,
      'monthlyFinanceData': instance.monthlyFinanceData,
      'recentActivities': instance.recentActivities,
    };
