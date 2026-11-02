import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart' show FeeLedger;
import 'package:abm_madrasa/features/hifz/data/hifz_repository.dart' show HifzRecord;
import 'package:abm_madrasa/features/homework/data/homework_repository.dart' show Homework;
import 'package:abm_madrasa/features/student_leave/data/student_leave_repository.dart' show StudentLeave;
import 'package:abm_madrasa/features/students/data/student_portal_repository.dart'
    show AttRecord, AttSummary, FeeSummary, PortalDay, PortalProfile, ReportRow;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One child summary as shown on the parent portal.
class ParentChild {
  const ParentChild({
    required this.studentId,
    required this.fullName,
    required this.admissionNumber,
    required this.grade,
    this.shift = '',
    this.gender = '',
    this.bloodGroup = '',
    this.dateOfBirth,
    this.guardianName = '',
    this.parentContact = '',
    required this.photoUrl,
    required this.present,
    required this.absent,
    required this.late,
    this.attendancePercentage = 0,
    required this.arrears,
    required this.currentDue,
    required this.balance,
    required this.advanceBalance,
    this.lastHifzSabaq,
    this.activeHomeworkCount = 0,
    this.pendingLeaveCount = 0,
  });

  final String studentId;
  final String fullName;
  final String admissionNumber;
  final String grade;
  final String shift;
  final String gender;
  final String bloodGroup;
  final DateTime? dateOfBirth;
  final String guardianName;
  final String parentContact;
  final String photoUrl;
  final int present, absent, late;
  final int attendancePercentage;
  final num arrears, currentDue, balance, advanceBalance;
  final String? lastHifzSabaq;
  final int activeHomeworkCount;
  final int pendingLeaveCount;

  factory ParentChild.fromJson(Map<String, dynamic> j) {
    final att = (j['attendance'] as Map?) ?? const {};
    final fin = (j['financials'] as Map?) ?? const {};
    final lastH = j['lastHifz'] as Map?;
    String? sabaq;
    if (lastH != null) {
      final surah = (lastH['sabaqSurah'] ?? '').toString();
      final from = (lastH['sabaqFrom'] ?? '').toString();
      final to = (lastH['sabaqTo'] ?? '').toString();
      final range = [from, to].where((s) => s.isNotEmpty).join('–');
      sabaq = [surah, range].where((s) => s.isNotEmpty).join(' ');
      if (sabaq.trim().isEmpty) sabaq = null;
    }

    return ParentChild(
      studentId: (j['studentId'] ?? j['_id'] ?? '').toString(),
      fullName: (j['fullName'] ?? '') as String,
      admissionNumber: (j['admissionNumber'] ?? '').toString(),
      grade: (j['grade'] ?? '') as String,
      shift: (j['shift'] ?? '') as String,
      gender: (j['gender'] ?? '') as String,
      bloodGroup: (j['bloodGroup'] ?? '') as String,
      dateOfBirth: j['dateOfBirth'] != null ? DateTime.tryParse(j['dateOfBirth'].toString()) : null,
      guardianName: (j['guardianName'] ?? '') as String,
      parentContact: (j['parentContact'] ?? '') as String,
      photoUrl: (j['photoUrl'] ?? '') as String,
      present: (att['present'] as num?)?.toInt() ?? 0,
      absent: (att['absent'] as num?)?.toInt() ?? 0,
      late: (att['late'] as num?)?.toInt() ?? 0,
      attendancePercentage: (att['percentage'] as num?)?.toInt() ?? 0,
      arrears: (fin['arrears'] ?? j['arrears'] ?? 0) as num,
      currentDue: (fin['currentDue'] ?? j['currentDue'] ?? 0) as num,
      balance: (fin['balance'] ?? j['balance'] ?? 0) as num,
      advanceBalance: (fin['advanceBalance'] ?? j['advanceBalance'] ?? 0) as num,
      lastHifzSabaq: sabaq,
      activeHomeworkCount: (j['activeHomeworkCount'] as num?)?.toInt() ?? 0,
      pendingLeaveCount: (j['pendingLeaveCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ParentOverview {
  const ParentOverview({
    required this.children,
    this.parentUsername = '',
    this.familyKey = '',
  });

  final List<ParentChild> children;
  final String parentUsername;
  final String familyKey;

  factory ParentOverview.fromJson(Map<String, dynamic> j) => ParentOverview(
        children: ((j['children'] as List?) ?? [])
            .map((e) => ParentChild.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        parentUsername: (j['parentUsername'] ?? '').toString(),
        familyKey: (j['familyKey'] ?? '').toString(),
      );
}

/// Comprehensive child dashboard data for the parent portal.
class ParentChildDetails {
  const ParentChildDetails({
    required this.profile,
    required this.attendanceSummary,
    required this.recentAttendance,
    required this.feesSummary,
    required this.fees,
    required this.reports,
    required this.hifzRecords,
    required this.homework,
    required this.timetable,
    required this.leaves,
  });

  final PortalProfile profile;
  final AttSummary attendanceSummary;
  final List<AttRecord> recentAttendance;
  final FeeSummary feesSummary;
  final List<dynamic> fees;
  final List<ReportRow> reports;
  final List<HifzRecord> hifzRecords;
  final List<Homework> homework;
  final List<PortalDay> timetable;
  final List<StudentLeave> leaves;

  factory ParentChildDetails.fromJson(Map<String, dynamic> j) {
    final hifzMap = (j['hifz'] as Map?) ?? const {};
    final hifzList = (hifzMap['records'] as List?) ?? const [];

    return ParentChildDetails(
      profile: PortalProfile.fromJson(Map<String, dynamic>.from(j['profile'] ?? {})),
      attendanceSummary: AttSummary.fromJson(Map<String, dynamic>.from(j['attendanceSummary'] ?? {})),
      recentAttendance: ((j['recentAttendance'] as List?) ?? [])
          .map((e) => AttRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      feesSummary: FeeSummary.fromJson(Map<String, dynamic>.from(j['feesSummary'] ?? {})),
      fees: (j['fees'] as List?) ?? const [],
      reports: ((j['reports'] as List?) ?? [])
          .map((e) => ReportRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      hifzRecords: hifzList
          .map((e) => HifzRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      homework: ((j['homework'] as List?) ?? [])
          .map((e) => Homework.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      timetable: ((j['timetable'] as List?) ?? [])
          .map((e) => PortalDay.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      leaves: ((j['leaves'] as List?) ?? [])
          .map((e) => StudentLeave.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(ref.watch(dioProvider));
});

class ParentRepository {
  ParentRepository(this._dio);
  final Dio _dio;

  Future<ParentOverview> getOverview() async {
    try {
      final res = await _dio.get('/parent-portal/overview');
      return ParentOverview.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      // Fallback to legacy endpoint if needed
      final res = await _dio.get('/accounts/parent/overview');
      return ParentOverview.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
  }

  Future<ParentChildDetails> getChildDetails(String studentId) async {
    final res = await _dio.get('/parent-portal/child/$studentId');
    return ParentChildDetails.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<FeeLedger> getChildLedger(String studentId) async {
    try {
      final res = await _dio.get('/accounts/parent/child/$studentId/ledger');
      return FeeLedger.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      throw Exception('Failed to load fee details: $e');
    }
  }

  Future<void> submitLeave({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    await _dio.post('/parent-portal/child/$studentId/leave', data: {
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'reason': reason,
    });
  }
}

final parentOverviewProvider =
    FutureProvider.autoDispose<ParentOverview>((ref) => ref.watch(parentRepositoryProvider).getOverview());

final parentChildDetailsProvider =
    FutureProvider.autoDispose.family<ParentChildDetails, String>((ref, studentId) {
  return ref.watch(parentRepositoryProvider).getChildDetails(studentId);
});

final parentChildLedgerProvider = FutureProvider.autoDispose.family<FeeLedger, String>(
  (ref, studentId) => ref.watch(parentRepositoryProvider).getChildLedger(studentId),
);
