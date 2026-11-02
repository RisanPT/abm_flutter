import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/attendance/domain/staff_checkin_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final staffCheckinRepositoryProvider = Provider<StaffCheckinRepository>((ref) {
  return StaffCheckinRepository(ref.watch(dioProvider));
});

class StaffCheckinRepository {
  StaffCheckinRepository(this._dio);
  final Dio _dio;

  Future<MyCheckinSummary> getMyCheckins({String? month}) async {
    try {
      final qp = <String, dynamic>{};
      if (month != null) qp['month'] = month;
      final res = await _dio.get('/staff-checkin/me', queryParameters: qp);
      return MyCheckinSummary.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load attendance: $e');
    }
  }

  Future<void> checkIn({
    String status = 'Present',
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _dio.post('/staff-checkin', data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
        'latitude': ?latitude,
        'longitude': ?longitude,
      });
    } on DioException catch (e) {
      // Surface the backend message (e.g. "outside perimeter" / "location required").
      final data = e.response?.data;
      final msg = data is Map ? data['message'] as String? : null;
      throw Exception(msg ?? 'Failed to check in');
    }
  }

  /// The institute's attendance geofence config. Falls back to disabled on error
  /// so a transient failure never blocks check-in when no restriction is set.
  Future<AttendanceGeofence> getGeofence(String instituteId) async {
    try {
      final res = await _dio.get('/institutes/$instituteId/attendance-geofence');
      return AttendanceGeofence.fromJson(Map<String, dynamic>.from(res.data));
    } catch (_) {
      return const AttendanceGeofence(enabled: false);
    }
  }
}

class AttendanceGeofence {
  const AttendanceGeofence({
    required this.enabled,
    this.latitude,
    this.longitude,
    this.radiusMeters = 200,
  });
  final bool enabled;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;

  factory AttendanceGeofence.fromJson(Map<String, dynamic> j) => AttendanceGeofence(
        enabled: j['enabled'] == true,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        radiusMeters: (j['radiusMeters'] as num?)?.toInt() ?? 200,
      );
}

/// My check-ins for the current month (+ today's status).
final myCheckinProvider = FutureProvider.autoDispose<MyCheckinSummary>((ref) {
  return ref.watch(staffCheckinRepositoryProvider).getMyCheckins();
});
