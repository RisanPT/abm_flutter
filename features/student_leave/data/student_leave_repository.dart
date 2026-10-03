import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentLeaveRepositoryProvider =
    Provider<StudentLeaveRepository>((ref) => StudentLeaveRepository(ref.watch(dioProvider)));

final myLeavesProvider =
    FutureProvider.autoDispose<List<StudentLeave>>((ref) => ref.read(studentLeaveRepositoryProvider).getMine());

class StudentLeaveQuery {
  const StudentLeaveQuery({this.status = 'Pending', this.classroom, this.page = 1});
  final String status;
  final String? classroom;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is StudentLeaveQuery &&
      status == other.status &&
      classroom == other.classroom &&
      page == other.page;

  @override
  int get hashCode => Object.hash(status, classroom, page);
}

final staffLeavesPageProvider =
    FutureProvider.autoDispose.family<PagedResult<StudentLeave>, StudentLeaveQuery>((ref, q) {
  ref.watch(selectedInstituteProvider);
  return ref.read(studentLeaveRepositoryProvider).listPage(
        status: q.status,
        classroom: q.classroom,
        page: q.page,
      );
});

/// Staff leave queue, keyed by status ('Pending' | 'Approved' | 'Rejected' | 'All').
final staffLeavesProvider = FutureProvider.autoDispose.family<List<StudentLeave>, String>((ref, status) {
  ref.watch(selectedInstituteProvider);
  return ref.read(studentLeaveRepositoryProvider).list(status: status);
});

class StudentLeave {
  const StudentLeave({
    required this.id,
    required this.studentId,
    this.studentName = '',
    this.classroom = '',
    this.fromDate,
    this.toDate,
    this.reason = '',
    this.status = 'Pending',
    this.decidedByName = '',
    this.decisionNote = '',
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String classroom;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String reason;
  final String status;
  final String decidedByName;
  final String decisionNote;
  final DateTime? createdAt;

  factory StudentLeave.fromJson(Map<String, dynamic> j) => StudentLeave(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        studentId: (j['studentId'] ?? '').toString(),
        studentName: (j['studentName'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        fromDate: j['fromDate'] != null ? DateTime.tryParse(j['fromDate'].toString()) : null,
        toDate: j['toDate'] != null ? DateTime.tryParse(j['toDate'].toString()) : null,
        reason: (j['reason'] ?? '').toString(),
        status: (j['status'] ?? 'Pending').toString(),
        decidedByName: (j['decidedByName'] ?? '').toString(),
        decisionNote: (j['decisionNote'] ?? '').toString(),
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );
}

class StudentLeaveRepository {
  StudentLeaveRepository(this._dio);
  final Dio _dio;

  Future<List<StudentLeave>> getMine() async {
    final r = await _dio.get('/student-leave/me');
    return (r.data as List).map((e) => StudentLeave.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<StudentLeave>> list({String? status, String? classroom}) async {
    final r = await _dio.get('/student-leave', queryParameters: {
      if (status != null && status != 'All') 'status': status,
      if (classroom != null && classroom != 'All') 'classroom': classroom,
    });
    return (r.data as List).map((e) => StudentLeave.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<PagedResult<StudentLeave>> listPage({
    String? status,
    String? classroom,
    required int page,
    int limit = 20,
  }) async {
    final r = await _dio.get('/student-leave', queryParameters: {
      if (status != null && status != 'All') 'status': status,
      if (classroom != null && classroom != 'All') 'classroom': classroom,
      'page': page,
      'limit': limit,
    });
    return PagedResult<StudentLeave>.fromJson(
      r.data as Map<String, dynamic>,
      (json) => StudentLeave.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<void> submit({required DateTime fromDate, required DateTime toDate, String reason = '', String? studentId}) async {
    await _dio.post('/student-leave', data: {
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'reason': reason,
      'studentId': ?studentId,
    });
  }

  Future<void> decide(String id, {required String status, String note = ''}) async {
    await _dio.patch('/student-leave/$id/decision', data: {'status': status, 'note': note});
  }

  Future<void> delete(String id) => _dio.delete('/student-leave/$id');
}
