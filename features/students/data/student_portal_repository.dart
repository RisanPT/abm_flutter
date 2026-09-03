import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Models (plain, no codegen) ───────────────────────────────────────────────

class PortalProfile {
  const PortalProfile({
    required this.fullName,
    required this.admissionNumber,
    required this.grade,
    this.shift,
    this.gender,
    this.guardianName,
    this.parentContact,
    this.address,
    this.photoUrl,
    this.bloodGroup,
  });
  final String fullName, admissionNumber, grade;
  final String? shift, gender, guardianName, parentContact, address, photoUrl, bloodGroup;

  factory PortalProfile.fromJson(Map<String, dynamic> j) => PortalProfile(
        fullName: (j['fullName'] ?? '').toString(),
        admissionNumber: (j['admissionNumber'] ?? '').toString(),
        grade: (j['grade'] ?? '').toString(),
        shift: j['shift'] as String?,
        gender: j['gender'] as String?,
        guardianName: j['guardianName'] as String?,
        parentContact: j['parentContact'] as String?,
        address: j['address'] as String?,
        photoUrl: j['photoUrl'] as String?,
        bloodGroup: j['bloodGroup'] as String?,
      );
}

class AttSummary {
  const AttSummary({required this.total, required this.present, required this.absent, required this.percentage});
  final int total, present, absent, percentage;
  factory AttSummary.fromJson(Map<String, dynamic> j) => AttSummary(
        total: (j['total'] ?? 0) as int,
        present: (j['present'] ?? 0) as int,
        absent: (j['absent'] ?? 0) as int,
        percentage: (j['percentage'] ?? 0) as int,
      );
}

class AttRecord {
  const AttRecord({required this.date, required this.status});
  final DateTime? date;
  final String status;
  factory AttRecord.fromJson(Map<String, dynamic> j) => AttRecord(
        date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) : null,
        status: (j['status'] ?? '').toString(),
      );
}

class FeeSummary {
  const FeeSummary({
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    this.advanceBalance = 0,
    this.arrears = 0,
    this.currentDue = 0,
  });
  final num totalDue, totalPaid, balance, advanceBalance, arrears, currentDue;
  factory FeeSummary.fromJson(Map<String, dynamic> j) => FeeSummary(
        totalDue: (j['totalDue'] ?? 0) as num,
        totalPaid: (j['totalPaid'] ?? 0) as num,
        balance: (j['balance'] ?? 0) as num,
        advanceBalance: (j['advanceBalance'] ?? 0) as num,
        arrears: (j['arrears'] ?? 0) as num,
        currentDue: (j['currentDue'] ?? 0) as num,
      );
}

class FeeRow {
  const FeeRow({required this.monthLabel, required this.totalDue, required this.totalPaid, required this.status});
  final String monthLabel, status;
  final num totalDue, totalPaid;
  factory FeeRow.fromJson(Map<String, dynamic> j) => FeeRow(
        monthLabel: (j['monthLabel'] ?? '').toString(),
        totalDue: (j['totalDue'] ?? 0) as num,
        totalPaid: (j['totalPaid'] ?? 0) as num,
        status: (j['status'] ?? 'Pending').toString(),
      );
}

class ReportGrade {
  const ReportGrade({required this.subject, required this.mark, required this.grade});
  final String subject, grade;
  final num mark;
  factory ReportGrade.fromJson(Map<String, dynamic> j) => ReportGrade(
        subject: (j['subject'] ?? '').toString(),
        mark: (j['mark'] ?? 0) as num,
        grade: (j['grade'] ?? '').toString(),
      );
}

class ReportRow {
  const ReportRow({
    required this.academicYear,
    required this.term,
    required this.remarks,
    required this.attendanceRate,
    required this.grades,
  });
  final String academicYear, term, remarks;
  final num attendanceRate;
  final List<ReportGrade> grades;
  factory ReportRow.fromJson(Map<String, dynamic> j) => ReportRow(
        academicYear: (j['academicYear'] ?? '').toString(),
        term: (j['term'] ?? '').toString(),
        remarks: (j['remarks'] ?? '').toString(),
        attendanceRate: (j['attendanceRate'] ?? 0) as num,
        grades: ((j['grades'] as List?) ?? [])
            .map((e) => ReportGrade.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class StudentPortalData {
  const StudentPortalData({
    required this.profile,
    required this.attendance,
    required this.recentAttendance,
    required this.fees,
    required this.feeRecords,
    required this.reports,
  });
  final PortalProfile profile;
  final AttSummary attendance;
  final List<AttRecord> recentAttendance;
  final FeeSummary fees;
  final List<FeeRow> feeRecords;
  final List<ReportRow> reports;

  factory StudentPortalData.fromJson(Map<String, dynamic> j) => StudentPortalData(
        profile: PortalProfile.fromJson(Map<String, dynamic>.from(j['student'])),
        attendance: AttSummary.fromJson(Map<String, dynamic>.from(j['attendanceSummary'] ?? {})),
        recentAttendance: ((j['recentAttendance'] as List?) ?? [])
            .map((e) => AttRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        fees: FeeSummary.fromJson(Map<String, dynamic>.from(j['feesSummary'] ?? {})),
        feeRecords: ((j['fees'] as List?) ?? [])
            .map((e) => FeeRow.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        reports: ((j['reports'] as List?) ?? [])
            .map((e) => ReportRow.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ── Repository + provider ────────────────────────────────────────────────────

final studentPortalRepositoryProvider =
    Provider<StudentPortalRepository>((ref) => StudentPortalRepository(ref.watch(dioProvider)));

class StudentPortalRepository {
  StudentPortalRepository(this._dio);
  final Dio _dio;

  Future<StudentPortalData> getMyPortal() async {
    final r = await _dio.get('/student-portal/me');
    return StudentPortalData.fromJson(Map<String, dynamic>.from(r.data));
  }
}

/// Auto-loading portal data for the current student.
final studentPortalProvider = FutureProvider.autoDispose<StudentPortalData>((ref) {
  return ref.watch(studentPortalRepositoryProvider).getMyPortal();
});
