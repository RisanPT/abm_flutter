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

  Future<void> checkIn({String status = 'Present', String? note}) async {
    try {
      await _dio.post('/staff-checkin', data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }
}

/// My check-ins for the current month (+ today's status).
final myCheckinProvider = FutureProvider.autoDispose<MyCheckinSummary>((ref) {
  return ref.watch(staffCheckinRepositoryProvider).getMyCheckins();
});
