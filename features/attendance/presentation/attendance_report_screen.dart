import 'dart:math' as math;
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/whatsapp/whatsapp_service.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/custom_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:abm_madrasa/core/utils/web_download.dart';

// ── Providers ────────────────────────────────────────────────────────────────

class _ReportParams {
  const _ReportParams({
    required this.month,
    required this.instituteId,
    required this.type,
    this.date,
    this.shift,
    this.refreshKey = 0,
  });
  final String month;
  final String? date;
  final String instituteId;
  final String type;
  final String? shift;
  final int refreshKey; // increment to force re-fetch same month/date

  @override
  bool operator ==(Object other) =>
      other is _ReportParams &&
      month == other.month &&
      date == other.date &&
      instituteId == other.instituteId &&
      type == other.type &&
      shift == other.shift &&
      refreshKey == other.refreshKey;

  @override
  int get hashCode => Object.hash(month, date, instituteId, type, shift, refreshKey);
}

final _attendanceReportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, _ReportParams>(
  (ref, params) async {
    final dio = ref.watch(dioProvider);
    final endpoint =
        params.type == 'teacher' ? '/attendance/teacher-report' : '/attendance/report';
    final queryParams = <String, dynamic>{
      'instituteId': params.instituteId,
    };
    if (params.date != null && params.date!.isNotEmpty) {
      queryParams['date'] = params.date;
    } else {
      queryParams['month'] = params.month;
    }
    if (params.shift != null && params.shift!.isNotEmpty && params.shift != 'All') {
      queryParams['shift'] = params.shift;
    }
    final response = await dio.get(endpoint, queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  },
);

// Per-teacher day-by-day rows for the drill-down.
class _TeacherDaysParams {
  const _TeacherDaysParams({required this.teacherId, required this.month, required this.instituteId, this.shift});
  final String teacherId;
  final String month;
  final String instituteId;
  final String? shift;
  @override
  bool operator ==(Object other) =>
      other is _TeacherDaysParams &&
      teacherId == other.teacherId &&
      month == other.month &&
      instituteId == other.instituteId &&
      shift == other.shift;
  @override
  int get hashCode => Object.hash(teacherId, month, instituteId, shift);
}

final _teacherDaysProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, _TeacherDaysParams>(
  (ref, p) async {
    final dio = ref.watch(dioProvider);
    final qp = <String, dynamic>{
      'month': p.month,
      'instituteId': p.instituteId,
    };
    if (p.shift != null && p.shift!.isNotEmpty && p.shift != 'All') {
      qp['shift'] = p.shift;
    }
    final res = await dio.get('/attendance/teacher-report/${p.teacherId}', queryParameters: qp);
    final days = ((res.data as Map)['days'] as List?) ?? [];
    return days.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  },
);

// Per-student day-by-day attendance history drill-down.
class _StudentDaysParams {
  const _StudentDaysParams({required this.studentId, required this.month, required this.instituteId});
  final String studentId;
  final String month;
  final String instituteId;
  @override
  bool operator ==(Object other) =>
      other is _StudentDaysParams &&
      studentId == other.studentId &&
      month == other.month &&
      instituteId == other.instituteId;
  @override
  int get hashCode => Object.hash(studentId, month, instituteId);
}

final _studentReportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, _StudentDaysParams>(
  (ref, p) async {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/attendance/student-report/${p.studentId}', queryParameters: {
      'month': p.month,
      'instituteId': p.instituteId,
    });
    return Map<String, dynamic>.from(res.data as Map);
  },
);

// ── Screen ───────────────────────────────────────────────────────────────────

class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String reportType; // 'student' or 'teacher'

  const AttendanceReportScreen({
    super.key,
    required this.reportType,
  });

  @override
  ConsumerState<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends ConsumerState<AttendanceReportScreen> {
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'day'; // 'day' or 'month'
  late String _reportType = widget.reportType;
  String _selectedShift = 'All'; // 'All', 'Shift-1', 'Shift-2'
  // A separate refresh counter so we can force-refetch with same month/day
  int _refreshKey = 0;

  @override
  void didUpdateWidget(covariant AttendanceReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportType != widget.reportType) {
      _reportType = widget.reportType;
    }
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedDate);
  String get _monthLabel => DateFormat('MMM yyyy').format(_selectedDate);
  String get _dayKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _dayLabel => DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

  Future<void> _refresh() async {
    setState(() => _refreshKey++);
  }

  void _stepDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
      _refreshKey++;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _refreshKey++;
      });
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await CustomMonthPicker.show(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: now,
    );
    if (picked != null) {
      if (picked.year != _selectedDate.year || picked.month != _selectedDate.month) {
        setState(() {
          _selectedDate = picked;
          _refreshKey++;
        });
      }
    }
  }

  Future<void> _exportAttendancePdf([String? overrideShift]) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    try {
      final institute = ref.read(selectedInstituteProvider);
      final instituteName = institute.name.trim().isNotEmpty
          ? institute.name.trim().toUpperCase()
          : 'ANAS BIN MALIK MADRASA';
      final isStudentTab = _reportType == 'student';
      final type = isStudentTab ? 'student' : 'teacher';
      final isDayWise = _viewMode == 'day';
      final effectiveShift = (overrideShift != null && overrideShift.isNotEmpty && overrideShift != 'All')
          ? (overrideShift == 'Shift 1' ? 'Shift-1' : (overrideShift == 'Shift 2' ? 'Shift-2' : overrideShift))
          : (overrideShift == 'All' ? 'All' : _selectedShift);
      final shiftLabel = effectiveShift == 'All' ? 'All Shifts' : effectiveShift;
      final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      final params = _ReportParams(
        month: _monthKey,
        date: isDayWise ? _dayKey : null,
        instituteId: institute.id,
        type: type,
        shift: effectiveShift,
        refreshKey: _refreshKey,
      );

      Map<String, dynamic> data;
      final existing = ref.read(_attendanceReportProvider(params));
      if (existing.hasValue) {
        data = existing.value!;
      } else {
        data = await ref.read(_attendanceReportProvider(params).future);
      }

      if (isDayWise) {
        if (!isStudentTab) {
          // Teacher daily PDF
          final teachers = (data['teachers'] as List?) ?? [];
          if (teachers.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No attendance data to export for this date.')),
              );
            }
            return;
          }

          int pCount = 0;
          int lCount = 0;
          int aCount = 0;
          int lvCount = 0;
          int ncCount = 0;
          int nsCount = 0;
          for (final row in teachers) {
            switch (_stateOf(Map<String, dynamic>.from(row as Map))) {
              case 'present':
                pCount++;
                break;
              case 'late':
                lCount++;
                break;
              case 'leave':
                lvCount++;
                break;
              case 'absent':
                aCount++;
                break;
              case 'not_scheduled':
                nsCount++;
                break;
              default:
                ncCount++;
            }
          }
          final schedCount = pCount + lCount + lvCount + aCount + ncCount;
          final staffRate = schedCount > 0 ? (((pCount + lCount) / schedCount) * 100).round() : 0;

          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (context) => [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        instituteName,
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'TEACHER DAILY ATTENDANCE REPORT',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Date: $_dayLabel', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Shift: $shiftLabel', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Generated: $generatedAt', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$schedCount scheduled today   |   Checked in: ${pCount + lCount} ($staffRate%)   |   Not checked in: $ncCount   |   On Leave: $lvCount${aCount > 0 ? '   |   Absent: $aCount' : ''}   |   Not scheduled: $nsCount',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Note: "Not checked in" means a scheduled teacher has no check-in yet — not a confirmed absence. "Not scheduled" teachers had no class today.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headers: ['Emp ID', 'Teacher Name', 'Shift', 'Status', 'Check-in Time', 'Method', 'Remarks / Leave'],
                  data: teachers.map((row) {
                    final r = row as Map<String, dynamic>;
                    String checkIn = '—';
                    final rawCheckIn = r['checkInAt'];
                    if (rawCheckIn != null) {
                      final dt = DateTime.tryParse(rawCheckIn.toString());
                      if (dt != null) {
                        checkIn = DateFormat('hh:mm a').format(dt.toLocal());
                      }
                    }
                    final leaveDetails = r['leaveDetails'] is Map ? (r['leaveDetails'] as Map) : null;
                    final leaveType = leaveDetails?['type'] ?? leaveDetails?['leaveType'] ?? '';
                    final leaveInfo = leaveDetails != null ? 'On Leave${leaveType.isNotEmpty ? ' ($leaveType)' : ''}' : '';
                    final sl = r['shifts'];
                    final rowShift = (sl is List && sl.isNotEmpty)
                        ? sl.join(', ')
                        : (_selectedShift != 'All' ? _selectedShift : '—');
                    return [
                      r['employeeId']?.toString() ?? '',
                      r['fullName']?.toString() ?? '',
                      rowShift,
                      _stateVisual(_stateOf(r)).label,
                      checkIn,
                      r['verificationMethod']?.toString() ?? '—',
                      (r['remarks']?.toString().isNotEmpty == true) ? r['remarks'] : (leaveInfo.isNotEmpty ? leaveInfo : '—'),
                    ];
                  }).toList(),
                ),
              ],
            ),
          );
          final bytes = await pdf.save();
          final fname = 'teacher_daily_attendance_$_dayKey.pdf';
          if (kIsWeb) {
            await Printing.layoutPdf(onLayout: (_) => bytes, name: fname);
          } else {
            await Printing.sharePdf(bytes: bytes, filename: fname, bounds: origin);
          }
          return;
        } else {
          // Student daily PDF
          final summary = (data['summary'] as List?) ?? [];
          final hasStudents = summary.any((c) => ((c as Map)['students'] as List?)?.isNotEmpty == true);
          if (summary.isEmpty || !hasStudents) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No attendance data to export for this date.')),
              );
            }
            return;
          }

          int totalPres = 0;
          int totalAbs = 0;
          int totalStudents = 0;
          for (final c in summary) {
            totalPres += (c['present'] as num?)?.toInt() ?? 0;
            totalAbs += (c['absent'] as num?)?.toInt() ?? 0;
            totalStudents += ((c['students'] as List?)?.length ?? 0);
          }
          final dailyRate = (totalPres + totalAbs) > 0 ? ((totalPres / (totalPres + totalAbs)) * 100).round() : 0;

          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (context) => [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        instituteName,
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'STUDENT DAILY ATTENDANCE REPORT',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Date: $_dayLabel', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Shift: $shiftLabel', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Generated: $generatedAt', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Total Classes: ${summary.length}   |   Total Students: $totalStudents   |   Present: $totalPres   |   Absent: $totalAbs   |   Rate: $dailyRate%',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
                ...summary.expand((cRow) {
                  final c = cRow as Map<String, dynamic>;
                  final cName = c['classroom']?.toString() ?? 'Unknown';
                  final cShift = (c['shift']?.toString().isNotEmpty == true)
                      ? c['shift'].toString()
                      : (_selectedShift != 'All' ? _selectedShift : '');
                  final students = (c['students'] as List?) ?? [];
                  if (students.isEmpty) return <pw.Widget>[];
                  return [
                    pw.SizedBox(height: 14),
                    pw.Text('Classroom: $cName${cShift.isNotEmpty ? ' · $cShift' : ''} (Present: ${c['present'] ?? 0}, Absent: ${c['absent'] ?? 0}, Rate: ${c['rate'] ?? 0}%)',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.TableHelper.fromTextArray(
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      cellStyle: const pw.TextStyle(fontSize: 8.5),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      headers: ['Admission No', 'Student Name', 'Status', 'Remarks', 'Parent Contact'],
                      data: students.map((sRow) {
                        final s = sRow as Map<String, dynamic>;
                        return [
                          s['admissionNumber']?.toString() ?? '',
                          s['fullName']?.toString() ?? '',
                          s['status']?.toString() ?? '',
                          s['remarks']?.toString() ?? '—',
                          s['parentContact']?.toString() ?? '—',
                        ];
                      }).toList(),
                    ),
                  ];
                }),
              ],
            ),
          );
          final bytes = await pdf.save();
          final fname = 'student_daily_attendance_$_dayKey.pdf';
          if (kIsWeb) {
            await Printing.layoutPdf(onLayout: (_) => bytes, name: fname);
          } else {
            await Printing.sharePdf(bytes: bytes, filename: fname, bounds: origin);
          }
          return;
        }
      }

      // Monthly PDF
      final summary = (data['summary'] as List?) ?? [];
      final studentSummary = (data['studentSummary'] as List?) ?? [];
      if (summary.isEmpty && studentSummary.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attendance data to export for this month.')),
          );
        }
        return;
      }

      if (isStudentTab) {
        // Student Monthly PDF
        int totalPres = 0;
        int totalAbs = 0;
        int totalLate = 0;
        int totalDays = 0;
        final studentRows = studentSummary.isNotEmpty ? studentSummary : summary;
        for (final r in studentRows) {
          totalPres += (r['present'] as num?)?.toInt() ?? 0;
          totalAbs += (r['absent'] as num?)?.toInt() ?? 0;
          totalLate += (r['late'] as num?)?.toInt() ?? 0;
          totalDays += (r['total'] as num?)?.toInt() ?? 0;
        }
        final avgRate = totalDays > 0 ? ((totalPres / totalDays) * 100).round() : 0;

        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      instituteName,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'STUDENT MONTHLY ATTENDANCE REPORT',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Evaluation Period: ${DateFormat('MMMM yyyy').format(_selectedDate)}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Shift: $shiftLabel', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Generated: $generatedAt', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Students: ${studentRows.length}   |   Present Days: $totalPres   |   Absent Days: $totalAbs   |   Late Days: $totalLate   |   Overall Rate: $avgRate%',
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              if (studentSummary.isNotEmpty)
                ...() {
                  final Map<String, List<Map<String, dynamic>>> byClass = {};
                  for (final s in studentSummary) {
                    final c = (s as Map<String, dynamic>)['classroom']?.toString() ?? 'Unknown';
                    byClass.putIfAbsent(c, () => []).add(s);
                  }

                  final List<pw.Widget> widgets = [];
                  for (final c in byClass.keys.toList()..sort()) {
                    widgets.add(pw.SizedBox(height: 14));
                    widgets.add(
                      pw.Text('Classroom: $c', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))
                    );
                    widgets.add(pw.SizedBox(height: 6));

                    final students = byClass[c]!..sort((a, b) =>
                      (a['fullName']?.toString() ?? '').compareTo(b['fullName']?.toString() ?? ''));

                    widgets.add(
                      pw.TableHelper.fromTextArray(
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                        cellStyle: const pw.TextStyle(fontSize: 8.5),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        headers: ['Admn No', 'Student Name', 'Shift', 'Present Days', 'Absent Days', 'Late Days', 'Total Days', 'Rate'],
                        data: students.map((r) {
                          final studentShift = (r['shift']?.toString().isNotEmpty == true)
                              ? r['shift'].toString()
                              : (_selectedShift != 'All' ? _selectedShift : '—');
                          return [
                            r['admissionNumber']?.toString() ?? '',
                            r['fullName']?.toString() ?? '',
                            studentShift,
                            r['present']?.toString() ?? '0',
                            r['absent']?.toString() ?? '0',
                            r['late']?.toString() ?? '0',
                            r['total']?.toString() ?? '0',
                            '${r['rate'] ?? 0}%',
                          ];
                        }).toList(),
                      )
                    );
                  }
                  return widgets;
                }()
              else
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headers: ['Classroom', 'Shift', 'Present Days', 'Absent Days', 'Late Days', 'Total Days', 'Attendance Rate'],
                  data: summary.map((row) {
                    final r = row as Map<String, dynamic>;
                    final rowShift = (r['shift']?.toString().isNotEmpty == true)
                        ? r['shift'].toString()
                        : (_selectedShift != 'All' ? _selectedShift : '—');
                    return [
                      r['classroom']?.toString() ?? '',
                      rowShift,
                      r['present']?.toString() ?? '0',
                      r['absent']?.toString() ?? '0',
                      r['late']?.toString() ?? '0',
                      r['total']?.toString() ?? '0',
                      '${r['rate'] ?? 0}%',
                    ];
                  }).toList(),
                )
            ],
          ),
        );
        final bytes = await pdf.save();
        final fname = 'student_monthly_attendance_$_monthKey.pdf';
        if (kIsWeb) {
          await Printing.layoutPdf(onLayout: (_) => bytes, name: fname);
        } else {
          await Printing.sharePdf(bytes: bytes, filename: fname, bounds: origin);
        }
        return;
      }

      // Teacher Monthly PDF (Landscape for optimal column layout)
      final pdf = pw.Document();
      int totalTeachers = summary.length;
      int totalScheduled = 0;
      int totalPresent = 0;
      int totalAbsent = 0;
      int totalLeave = 0;
      int totalLate = 0;
      int totalDays = 0;
      for (final row in summary) {
        final r = row as Map<String, dynamic>;
        totalScheduled += (r['scheduledDays'] as num?)?.toInt() ?? 0;
        totalPresent += (r['present'] as num?)?.toInt() ?? 0;
        totalAbsent += (r['absent'] as num?)?.toInt() ?? 0;
        totalLeave += (r['leave'] as num?)?.toInt() ?? 0;
        totalLate += (r['late'] as num?)?.toInt() ?? 0;
        totalDays += (r['total'] as num?)?.toInt() ?? 0;
      }
      final overallRate = totalDays > 0 ? ((totalPresent / totalDays) * 100).round() : 0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    instituteName,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'TEACHER MONTHLY ATTENDANCE REPORT',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Evaluation Period: ${DateFormat('MMMM yyyy').format(_selectedDate)}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Shift: $shiftLabel', style: const pw.TextStyle(fontSize: 10)),
                      if (data['instituteWorkingDays'] != null || data['totalWorkingDays'] != null)
                        pw.Text('Madrasa Working Days: ${data['instituteWorkingDays'] ?? data['totalWorkingDays']}', style:  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Generated: $generatedAt', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total Teachers: $totalTeachers   |   Scheduled Days: $totalScheduled   |   Present Days: $totalPresent   |   Absent Days: $totalAbsent   |   On Leave: $totalLeave   |   Late Days: $totalLate   |   Overall Attendance Rate: $overallRate%',
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Note: "Scheduled Days" = the madrasa\'s planned working days for the month (the same base for every teacher); Present/Absent are counted against it.'
                    '${effectiveShift == 'Shift-1' || effectiveShift == 'Shift-2' ? ' This report counts $effectiveShift working days only; a dual-shift teacher\'s other-shift days are excluded.' : ''}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headers: ['Emp ID', 'Teacher Name', 'Shift', 'Assigned Classes', 'Scheduled', 'Present', 'Absent', 'Leave', 'Late', 'Total Days', 'Rate %'],
              data: summary.map((row) {
                final r = row as Map<String, dynamic>;
                final sl = r['shifts'];
                final isDual = r['isDualShift'] == true;
                final rawShift = r['displayShift']?.toString() ?? ((sl is List && sl.isNotEmpty)
                    ? sl.join(', ')
                    : (effectiveShift != 'All' ? effectiveShift : '—'));
                final rowShift = (effectiveShift != 'All' && isDual && !rawShift.contains('Dual'))
                    ? '$effectiveShift (Dual)'
                    : rawShift;
                final rawClasses = (r['classes'] as List?)?.map((e) => e.toString().trim()).where((c) => c.isNotEmpty).toList() ?? [];
                final classes = rawClasses.isNotEmpty ? rawClasses.join(', ') : '—';
                final scheduled = (r['scheduledDays'] as num?)?.toInt() ?? (r['total'] as num?)?.toInt() ?? 0;
                final pres = (r['present'] as num?)?.toInt() ?? 0;
                final abs = (r['absent'] as num?)?.toInt() ?? 0;
                final leave = (r['leave'] as num?)?.toInt() ?? 0;
                final late = (r['late'] as num?)?.toInt() ?? 0;
                final tot = (r['total'] as num?)?.toInt() ?? scheduled;
                final rate = (r['rate'] as num?)?.toInt() ?? (tot > 0 ? ((pres / tot) * 100).round() : 0);
                return [
                  r['employeeId']?.toString() ?? '',
                  r['fullName']?.toString() ?? '',
                  rowShift,
                  classes,
                  '$scheduled',
                  '$pres',
                  '$abs',
                  '$leave',
                  '$late',
                  '$tot',
                  '$rate%',
                ];
              }).toList(),
            ),
          ],
        ),
      );
      final bytes = await pdf.save();
      final fname = '${type}_monthly_attendance_$_monthKey.pdf';
      if (kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) => bytes, name: fname);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fname, bounds: origin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _exportAttendanceExcel([String? overrideShift]) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    try {
      final institute = ref.read(selectedInstituteProvider);
      final instituteName = institute.name.trim().isNotEmpty
          ? institute.name.trim().toUpperCase()
          : 'ANAS BIN MALIK MADRASA';
      final isStudentTab = _reportType == 'student';
      final type = isStudentTab ? 'student' : 'teacher';
      final isDayWise = _viewMode == 'day';
      final effectiveShift = (overrideShift != null && overrideShift.isNotEmpty && overrideShift != 'All')
          ? (overrideShift == 'Shift 1' ? 'Shift-1' : (overrideShift == 'Shift 2' ? 'Shift-2' : overrideShift))
          : (overrideShift == 'All' ? 'All' : _selectedShift);
      final shiftLabel = effectiveShift == 'All' ? 'All Shifts' : effectiveShift;
      final periodLabel = isDayWise ? _dayLabel : DateFormat('MMMM yyyy').format(_selectedDate);
      final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

      final params = _ReportParams(
        month: _monthKey,
        date: isDayWise ? _dayKey : null,
        instituteId: institute.id,
        type: type,
        shift: effectiveShift,
        refreshKey: _refreshKey,
      );

      Map<String, dynamic> data;
      final existing = ref.read(_attendanceReportProvider(params));
      if (existing.hasValue) {
        data = existing.value!;
      } else {
        data = await ref.read(_attendanceReportProvider(params).future);
      }

      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];

      // Reusable Cell Styles for Professional Excel Output
      final titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final subTitleStyle = CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#1F2937'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final bannerStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#4B5563'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headerStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final centerStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final leftStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      if (isDayWise) {
        if (!isStudentTab) {
          // Teacher daily excel
          final rows = (data['teachers'] as List?) ?? [];
          if (rows.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No attendance data to export for this date.')),
              );
            }
            return;
          }

          int pCount = 0;
          int lCount = 0;
          int aCount = 0;
          int lvCount = 0;
          int ncCount = 0;
          int nsCount = 0;
          for (final r in rows) {
            switch (_stateOf(Map<String, dynamic>.from(r as Map))) {
              case 'present':
                pCount++;
                break;
              case 'late':
                lCount++;
                break;
              case 'leave':
                lvCount++;
                break;
              case 'absent':
                aCount++;
                break;
              case 'not_scheduled':
                nsCount++;
                break;
              default:
                ncCount++;
            }
          }
          final schedCount = pCount + lCount + lvCount + aCount + ncCount;
          final staffRate = schedCount > 0 ? (((pCount + lCount) / schedCount) * 100).round() : 0;

          // Set explicit generous column widths (7 columns: 0 to 6)
          sheet.setColumnWidth(0, 16.0); // Employee ID
          sheet.setColumnWidth(1, 32.0); // Teacher Name
          sheet.setColumnWidth(2, 20.0); // Shift
          sheet.setColumnWidth(3, 16.0); // Status
          sheet.setColumnWidth(4, 18.0); // Check-in Time
          sheet.setColumnWidth(5, 20.0); // Method
          sheet.setColumnWidth(6, 32.0); // Remarks / Leave Details

          // Merged Institutional Header Rows
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
            customValue: TextCellValue(instituteName),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1),
            customValue: TextCellValue('TEACHER DAILY ATTENDANCE REPORT'),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = subTitleStyle;

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2),
            customValue: TextCellValue('Date: $periodLabel   |   Shift: $shiftLabel   |   Generated: $generatedAt'),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = bannerStyle;

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 3),
            customValue: TextCellValue('$schedCount scheduled today   |   Checked in: ${pCount + lCount} ($staffRate%)   |   Not checked in: $ncCount   |   On Leave: $lvCount${aCount > 0 ? '   |   Absent: $aCount' : ''}   |   Not scheduled: $nsCount'),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle = bannerStyle;

          // Row 5 (rowIndex 4): clarity note
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 4),
            customValue: TextCellValue('"Not checked in" = a scheduled teacher with no check-in yet (not a confirmed absence). "Not scheduled" = no class today.'),
          );

          // Row 6 (rowIndex 5): Column Headers
          final headers = [
            'Employee ID',
            'Teacher Name',
            'Shift',
            'Status',
            'Check-in Time',
            'Method',
            'Remarks / Leave Details'
          ];
          for (int c = 0; c < headers.length; c++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 5));
            cell.value = TextCellValue(headers[c]);
            cell.cellStyle = headerStyle;
          }

          for (int rIdx = 0; rIdx < rows.length; rIdx++) {
            final r = rows[rIdx] as Map<String, dynamic>;
            final currentRow = 6 + rIdx;
            String checkIn = '—';
            final rawCheckIn = r['checkInAt'];
            if (rawCheckIn != null) {
              final dt = DateTime.tryParse(rawCheckIn.toString());
              if (dt != null) {
                checkIn = DateFormat('hh:mm a').format(dt.toLocal());
              }
            }
            final leaveDetails = r['leaveDetails'] is Map ? (r['leaveDetails'] as Map) : null;
            final leaveType = leaveDetails?['type'] ?? leaveDetails?['leaveType'] ?? '';
            final leaveInfo = leaveDetails != null ? 'On Leave${leaveType.isNotEmpty ? ' ($leaveType)' : ''}' : '';
            final sl = r['shifts'];
            final rowShift = (sl is List && sl.isNotEmpty)
                ? sl.join(', ')
                : (_selectedShift != 'All' ? _selectedShift : '—');

            String rawId = r['employeeId']?.toString().trim() ?? '';
            if (rawId.isNotEmpty && int.tryParse(rawId) != null) {
              rawId = rawId.padLeft(4, '0');
            }

            final c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
            c0.value = TextCellValue(rawId);
            c0.cellStyle = centerStyle;

            final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
            c1.value = TextCellValue(r['fullName']?.toString() ?? '');
            c1.cellStyle = leftStyle;

            final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
            c2.value = TextCellValue(rowShift);
            c2.cellStyle = centerStyle;

            final c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
            c3.value = TextCellValue(_stateVisual(_stateOf(r)).label);
            c3.cellStyle = centerStyle;

            final c4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
            c4.value = TextCellValue(checkIn);
            c4.cellStyle = centerStyle;

            final c5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
            c5.value = TextCellValue(r['verificationMethod']?.toString() ?? '—');
            c5.cellStyle = centerStyle;

            final c6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
            c6.value = TextCellValue((r['remarks']?.toString().isNotEmpty == true) ? r['remarks'] : (leaveInfo.isNotEmpty ? leaveInfo : '—'));
            c6.cellStyle = leftStyle;
          }
        } else {
          // Student daily excel
          final summary = (data['summary'] as List?) ?? [];
          final hasStudents = summary.any((c) => ((c as Map)['students'] as List?)?.isNotEmpty == true);
          if (summary.isEmpty || !hasStudents) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No attendance data to export for this date.')),
              );
            }
            return;
          }

          int totalPres = 0;
          int totalAbs = 0;
          int totalStudents = 0;
          for (final c in summary) {
            totalPres += (c['present'] as num?)?.toInt() ?? 0;
            totalAbs += (c['absent'] as num?)?.toInt() ?? 0;
            totalStudents += ((c['students'] as List?)?.length ?? 0);
          }
          final dailyRate = (totalPres + totalAbs) > 0 ? ((totalPres / (totalPres + totalAbs)) * 100).round() : 0;

          // Set column widths (7 columns: 0 to 6)
          sheet.setColumnWidth(0, 18.0); // Classroom
          sheet.setColumnWidth(1, 18.0); // Shift
          sheet.setColumnWidth(2, 18.0); // Admission No
          sheet.setColumnWidth(3, 30.0); // Student Name
          sheet.setColumnWidth(4, 16.0); // Status
          sheet.setColumnWidth(5, 24.0); // Remarks
          sheet.setColumnWidth(6, 22.0); // Parent Contact

          // Merged Institutional Header Rows
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
            customValue: TextCellValue(instituteName),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1),
            customValue: TextCellValue('STUDENT DAILY ATTENDANCE REPORT'),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = subTitleStyle;

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2),
            customValue: TextCellValue('Date: $periodLabel   |   Shift: $shiftLabel   |   Generated: $generatedAt'),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = bannerStyle;

          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 3),
            customValue: TextCellValue('Total Classes: ${summary.length}   |   Students Recorded: $totalStudents   |   Present: $totalPres   |   Absent: $totalAbs   |   Rate: $dailyRate%'),
          );
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle = bannerStyle;

          // Column Headers
          final headers = [
            'Classroom',
            'Shift',
            'Admission No',
            'Student Name',
            'Status',
            'Remarks',
            'Parent Contact'
          ];
          for (int c = 0; c < headers.length; c++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 5));
            cell.value = TextCellValue(headers[c]);
            cell.cellStyle = headerStyle;
          }

          int currentRow = 6;
          for (final cRow in summary) {
            final c = cRow as Map<String, dynamic>;
            final cName = c['classroom']?.toString() ?? '';
            final cShift = (c['shift']?.toString().isNotEmpty == true)
                ? c['shift'].toString()
                : (_selectedShift != 'All' ? _selectedShift : '—');
            final students = (c['students'] as List?) ?? [];
            for (final sRow in students) {
              final s = sRow as Map<String, dynamic>;

              final c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
              c0.value = TextCellValue(cName);
              c0.cellStyle = centerStyle;

              final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
              c1.value = TextCellValue(cShift);
              c1.cellStyle = centerStyle;

              final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
              c2.value = TextCellValue(s['admissionNumber']?.toString() ?? '');
              c2.cellStyle = centerStyle;

              final c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
              c3.value = TextCellValue(s['fullName']?.toString() ?? '');
              c3.cellStyle = leftStyle;

              final c4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
              c4.value = TextCellValue(s['status']?.toString() ?? '');
              c4.cellStyle = centerStyle;

              final c5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
              c5.value = TextCellValue(s['remarks']?.toString() ?? '—');
              c5.cellStyle = leftStyle;

              final c6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
              c6.value = TextCellValue(s['parentContact']?.toString() ?? '—');
              c6.cellStyle = centerStyle;

              currentRow++;
            }
          }
        }
        final bytes = excel.encode();
        if (bytes == null) return;
        final fname = '${type}_daily_attendance_$_dayKey.xlsx';
        if (kIsWeb) {
          triggerBrowserDownload(bytes, fname, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded $fname')));
          return;
        }
        try {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/$fname');
          await file.writeAsBytes(bytes, flush: true);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', name: fname)],
            text: '${isStudentTab ? 'Student' : 'Teacher'} daily attendance report — $_dayLabel',
            sharePositionOrigin: origin,
          );
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
        return;
      }

      if (isStudentTab) {
        // Student Monthly Excel
        final rows = (data['studentSummary'] as List?) ?? [];
        if (rows.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No attendance data to export for this month.')),
            );
          }
          return;
        }

        int totalPres = 0;
        int totalAbs = 0;
        int totalLate = 0;
        int totalDays = 0;
        for (final r in rows) {
          totalPres += (r['present'] as num?)?.toInt() ?? 0;
          totalAbs += (r['absent'] as num?)?.toInt() ?? 0;
          totalLate += (r['late'] as num?)?.toInt() ?? 0;
          totalDays += (r['total'] as num?)?.toInt() ?? 0;
        }
        final avgRate = totalDays > 0 ? ((totalPres / totalDays) * 100).round() : 0;

        // Set column widths (9 columns: 0 to 8)
        sheet.setColumnWidth(0, 18.0); // Admission No
        sheet.setColumnWidth(1, 30.0); // Student Name
        sheet.setColumnWidth(2, 18.0); // Classroom
        sheet.setColumnWidth(3, 18.0); // Shift
        sheet.setColumnWidth(4, 16.0); // Present Days
        sheet.setColumnWidth(5, 16.0); // Absent Days
        sheet.setColumnWidth(6, 14.0); // Late Days
        sheet.setColumnWidth(7, 16.0); // Total Days
        sheet.setColumnWidth(8, 18.0); // Attendance Rate %

        // Merged Institutional Header Rows
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0),
          customValue: TextCellValue(instituteName),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1),
          customValue: TextCellValue('STUDENT MONTHLY ATTENDANCE REPORT'),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = subTitleStyle;

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 2),
          customValue: TextCellValue('Evaluation Period: $periodLabel   |   Shift: $shiftLabel   |   Generated: $generatedAt'),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = bannerStyle;

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 3),
          customValue: TextCellValue('Total Students: ${rows.length}   |   Present Days: $totalPres   |   Absent Days: $totalAbs   |   Late Days: $totalLate   |   Overall Attendance Rate: $avgRate%'),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle = bannerStyle;

        // Column Headers
        final headers = [
          'Admission No',
          'Student Name',
          'Classroom',
          'Shift',
          'Present Days',
          'Absent Days',
          'Late Days',
          'Total Days',
          'Attendance Rate %'
        ];
        for (int c = 0; c < headers.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 5));
          cell.value = TextCellValue(headers[c]);
          cell.cellStyle = headerStyle;
        }

        for (int rIdx = 0; rIdx < rows.length; rIdx++) {
          final r = rows[rIdx] as Map<String, dynamic>;
          final currentRow = 6 + rIdx;
          final pres = (r['present'] as num?)?.toInt() ?? 0;
          final abs = (r['absent'] as num?)?.toInt() ?? 0;
          final late = (r['late'] as num?)?.toInt() ?? 0;
          final tot = (r['total'] as num?)?.toInt() ?? 0;
          final rate = (r['rate'] as num?)?.toInt() ?? (tot > 0 ? ((pres / tot) * 100).round() : 0);

          final c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
          c0.value = TextCellValue(r['admissionNumber']?.toString() ?? '');
          c0.cellStyle = centerStyle;

          final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
          c1.value = TextCellValue(r['fullName']?.toString() ?? '');
          c1.cellStyle = leftStyle;

          final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
          c2.value = TextCellValue(r['classroom']?.toString() ?? '');
          c2.cellStyle = centerStyle;

          final c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
          c3.value = TextCellValue((r['shift']?.toString().isNotEmpty == true)
              ? r['shift'].toString()
              : (_selectedShift != 'All' ? _selectedShift : '—'));
          c3.cellStyle = centerStyle;

          final c4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
          c4.value = IntCellValue(pres);
          c4.cellStyle = centerStyle;

          final c5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
          c5.value = IntCellValue(abs);
          c5.cellStyle = centerStyle;

          final c6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
          c6.value = IntCellValue(late);
          c6.cellStyle = centerStyle;

          final c7 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow));
          c7.value = IntCellValue(tot);
          c7.cellStyle = centerStyle;

          final c8 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow));
          c8.value = TextCellValue('$rate%');
          c8.cellStyle = centerStyle;
        }
      } else {
        // Teacher Monthly Excel
        final rows = (data['summary'] as List?) ?? [];
        if (rows.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No attendance data to export for this month.')),
            );
          }
          return;
        }

        int totalTeachers = rows.length;
        int totalScheduled = 0;
        int totalPresent = 0;
        int totalAbsent = 0;
        int totalLeave = 0;
        int totalLate = 0;
        int totalDays = 0;
        for (final r in rows) {
          totalScheduled += (r['scheduledDays'] as num?)?.toInt() ?? 0;
          totalPresent += (r['present'] as num?)?.toInt() ?? 0;
          totalAbsent += (r['absent'] as num?)?.toInt() ?? 0;
          totalLeave += (r['leave'] as num?)?.toInt() ?? 0;
          totalLate += (r['late'] as num?)?.toInt() ?? 0;
          totalDays += (r['total'] as num?)?.toInt() ?? 0;
        }
        final overallRate = totalDays > 0 ? ((totalPresent / totalDays) * 100).round() : 0;

        // Set generous column widths (11 columns: 0 to 10)
        sheet.setColumnWidth(0, 16.0); // Employee ID
        sheet.setColumnWidth(1, 32.0); // Teacher Name
        sheet.setColumnWidth(2, 22.0); // Shift
        sheet.setColumnWidth(3, 24.0); // Assigned Classes
        sheet.setColumnWidth(4, 18.0); // Scheduled Days
        sheet.setColumnWidth(5, 16.0); // Present Days
        sheet.setColumnWidth(6, 16.0); // Absent Days
        sheet.setColumnWidth(7, 14.0); // On Leave
        sheet.setColumnWidth(8, 14.0); // Late Days
        sheet.setColumnWidth(9, 20.0); // Total Working Days
        sheet.setColumnWidth(10, 20.0); // Attendance Rate %

        // Merged Institutional Header Rows (Merged A to K)
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0),
          customValue: TextCellValue(instituteName),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 1),
          customValue: TextCellValue('TEACHER MONTHLY ATTENDANCE REPORT'),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = subTitleStyle;

        final instituteWorkingDays = (data['instituteWorkingDays'] as num?)?.toInt() ?? (data['totalWorkingDays'] as num?)?.toInt() ?? 0;
        final workingDaysInfo = instituteWorkingDays > 0 ? '   |   Madrasa Working Days: $instituteWorkingDays' : '';

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 2),
          customValue: TextCellValue('Evaluation Period: $periodLabel   |   Shift: $shiftLabel$workingDaysInfo   |   Generated: $generatedAt'),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = bannerStyle;

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 3),
          customValue: TextCellValue('Total Teachers: $totalTeachers   |   Scheduled Days: $totalScheduled   |   Present Days: $totalPresent   |   Absent Days: $totalAbsent   |   On Leave: $totalLeave   |   Late Days: $totalLate   |   Overall Attendance Rate: $overallRate%'),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle = bannerStyle;

        // Row 5 (rowIndex 4): clarity note on Scheduled Days
        final schedNote = '“Scheduled Days” = the madrasa\'s planned working days for the month (the same base for every teacher); Present/Absent are counted against it.'
            '${effectiveShift == 'Shift-1' || effectiveShift == 'Shift-2' ? ' This report counts $effectiveShift working days only; a dual-shift teacher\'s other-shift days are excluded.' : ''}';
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4),
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 4),
          customValue: TextCellValue(schedNote),
        );

        // Row 6 (rowIndex 5): Column Headers with dark navy background & bold white text
        final headers = [
          'Employee ID',
          'Teacher Name',
          'Shift',
          'Assigned Classes',
          'Scheduled Days',
          'Present Days',
          'Absent Days',
          'On Leave',
          'Late Days',
          'Total Working Days',
          'Attendance Rate %'
        ];
        for (int c = 0; c < headers.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 5));
          cell.value = TextCellValue(headers[c]);
          cell.cellStyle = headerStyle;
        }

        // Data Rows starting from rowIndex 6
        for (int rIdx = 0; rIdx < rows.length; rIdx++) {
          final r = rows[rIdx] as Map<String, dynamic>;
          final currentRow = 6 + rIdx;

          final sl = r['shifts'];
          final isDual = r['isDualShift'] == true;
          final rawShift = r['displayShift']?.toString() ?? ((sl is List && sl.isNotEmpty)
              ? sl.join(', ')
              : (effectiveShift != 'All' ? effectiveShift : '—'));
          final rowShift = (effectiveShift != 'All' && isDual && !rawShift.contains('Dual'))
              ? '$effectiveShift (Dual)'
              : rawShift;
          final rawClasses = (r['classes'] as List?)?.map((e) => e.toString().trim()).where((c) => c.isNotEmpty).toList() ?? [];
          final classes = rawClasses.isNotEmpty ? rawClasses.join(', ') : '—';
          final scheduled = (r['scheduledDays'] as num?)?.toInt() ?? (r['total'] as num?)?.toInt() ?? 0;
          final pres = (r['present'] as num?)?.toInt() ?? 0;
          final abs = (r['absent'] as num?)?.toInt() ?? 0;
          final leave = (r['leave'] as num?)?.toInt() ?? 0;
          final late = (r['late'] as num?)?.toInt() ?? 0;
          final tot = (r['total'] as num?)?.toInt() ?? scheduled;
          final rate = (r['rate'] as num?)?.toInt() ?? (tot > 0 ? ((pres / tot) * 100).round() : 0);

          String rawId = r['employeeId']?.toString().trim() ?? '';
          if (rawId.isNotEmpty && int.tryParse(rawId) != null) {
            rawId = rawId.padLeft(4, '0');
          }

          // Col 0: Employee ID (Center)
          final c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
          c0.value = TextCellValue(rawId);
          c0.cellStyle = centerStyle;

          // Col 1: Teacher Name (Left, generously wide)
          final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
          c1.value = TextCellValue(r['fullName']?.toString() ?? '');
          c1.cellStyle = leftStyle;

          // Col 2: Shift (Center)
          final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
          c2.value = TextCellValue(rowShift);
          c2.cellStyle = centerStyle;

          // Col 3: Assigned Classes (Center)
          final c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
          c3.value = TextCellValue(classes.isNotEmpty ? classes : '—');
          c3.cellStyle = centerStyle;

          // Col 4: Scheduled Days (Center)
          final c4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
          c4.value = IntCellValue(scheduled);
          c4.cellStyle = centerStyle;

          // Col 5: Present Days (Center)
          final c5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
          c5.value = IntCellValue(pres);
          c5.cellStyle = centerStyle;

          // Col 6: Absent Days (Center)
          final c6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
          c6.value = IntCellValue(abs);
          c6.cellStyle = centerStyle;

          // Col 7: On Leave (Center)
          final c7 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow));
          c7.value = IntCellValue(leave);
          c7.cellStyle = centerStyle;

          // Col 8: Late Days (Center)
          final c8 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow));
          c8.value = IntCellValue(late);
          c8.cellStyle = centerStyle;

          // Col 9: Total Working Days (Center)
          final c9 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow));
          c9.value = IntCellValue(tot);
          c9.cellStyle = centerStyle;

          // Col 10: Attendance Rate % (Center)
          final c10 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow));
          c10.value = TextCellValue('$rate%');
          c10.cellStyle = centerStyle;
        }
      }

      final bytes = excel.encode();
      if (bytes == null) return;
      final fname = '${type}_attendance_$_monthKey.xlsx';
      if (kIsWeb) {
        triggerBrowserDownload(bytes, fname, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded $fname')));
        return;
      }
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fname');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', name: fname)],
          text: '${isStudentTab ? 'Student' : 'Teacher'} attendance report — $_monthLabel',
          sharePositionOrigin: origin,
        );
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  void _showDownloadOptions(BuildContext context, {String? presetShift}) {
    final colors = context.colors;
    final typography = context.typography;
    final isStudent = _reportType == 'student';
    final isDayWise = _viewMode == 'day';
    final periodText = isDayWise ? _dayLabel : _monthLabel;

    // What the file will cover. Defaults to the shift already selected on screen
    // (or an explicit preset from an inline button), but the client can change it
    // right here so it's unambiguous which shift the download includes.
    String norm(String? s) {
      if (s == 'Shift 1' || s == 'Shift-1') return 'Shift-1';
      if (s == 'Shift 2' || s == 'Shift-2') return 'Shift-2';
      if (s == 'All' || s == 'All Shifts' || s == null || s.isEmpty) return 'All';
      return 'All';
    }

    String downloadShift = norm(presetShift ?? _selectedShift);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.downloadCloud, color: colors.primary, size: 22),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Download report', style: typography.h4),
                          Text(
                            '${isStudent ? 'Student' : 'Teacher'} attendance • ${isDayWise ? 'Day' : 'Month'}: $periodText',
                            style: typography.caption.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(18),
                // 1) Which shift to include
                Text('Which shift to include', style: typography.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                const Gap(8),
                Row(
                  children: [
                    for (final opt in const [('All', 'All shifts'), ('Shift-1', 'Shift 1'), ('Shift-2', 'Shift 2')]) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => downloadShift = opt.$1),
                          child: Container(
                            margin: EdgeInsets.only(right: opt.$1 == 'Shift-2' ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: downloadShift == opt.$1 ? colors.primary : colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: downloadShift == opt.$1 ? colors.primary : colors.border,
                                width: downloadShift == opt.$1 ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              opt.$2,
                              style: TextStyle(
                                color: downloadShift == opt.$1 ? Colors.white : colors.textPrimary,
                                fontSize: 13,
                                fontWeight: downloadShift == opt.$1 ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(8),
                Text(
                  downloadShift == 'All'
                      ? 'The file will include every shift.'
                      : 'The file will include ${downloadShift == 'Shift-1' ? 'Shift 1' : 'Shift 2'} only.',
                  style: typography.caption.copyWith(color: colors.textSecondary),
                ),
                const Gap(18),
                // 2) Choose a format
                Text('Choose a format', style: typography.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                const Gap(8),
                _downloadFormatTile(
                  context,
                  icon: LucideIcons.fileText,
                  iconColor: Colors.red,
                  title: 'PDF document',
                  subtitle: 'Formatted report to share or print',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportAttendancePdf(downloadShift);
                  },
                ),
                const Gap(12),
                _downloadFormatTile(
                  context,
                  icon: LucideIcons.table,
                  iconColor: Colors.green,
                  title: 'Excel spreadsheet (.xlsx)',
                  subtitle: 'Full breakdown for your own calculations',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportAttendanceExcel(downloadShift);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _downloadFormatTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: typography.bodyMediumSemiBold),
                    const Gap(2),
                    Text(subtitle, style: typography.caption.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final institute = ref.watch(selectedInstituteProvider);
    final isStudent = _reportType == 'student';

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          AbmGradientHeader(
            title: isStudent ? 'Student Report' : 'Teacher Report',
            leading: !context.isDesktop
                ? Builder(
                    builder: (c) => IconButton(
                      icon: const Icon(LucideIcons.menu, color: Colors.white),
                      onPressed: () => Scaffold.maybeOf(c)?.openDrawer(),
                    ),
                  )
                : const SizedBox(width: 40),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AbmHeaderIconButton(icon: LucideIcons.refreshCw, onTap: _refresh, tooltip: 'Refresh'),
                const Gap(8),
                InkWell(
                  onTap: () => _showDownloadOptions(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.download, size: 14, color: Colors.white),
                        const Gap(6),
                        Text(
                          'Download',
                          style: typography.bodySmallSemiBold.copyWith(color: Colors.white),
                        ),
                        const Gap(4),
                        const Icon(LucideIcons.chevronDown, size: 13, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                if (context.isDesktop) const SizedBox(width: 76),
              ],
            ),
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Segmented Mode Toggle: Day-Wise vs Monthly Summary
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeaderSegmentTab(
                        label: 'Day-Wise',
                        isSelected: _viewMode == 'day',
                        onTap: () => setState(() => _viewMode = 'day'),
                      ),
                      _HeaderSegmentTab(
                        label: 'Monthly Summary',
                        isSelected: _viewMode == 'month',
                        onTap: () => setState(() => _viewMode = 'month'),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                if (_viewMode == 'day')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                        onPressed: () => _stepDay(-1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Previous Day',
                      ),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.calendar, size: 15, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(_dayLabel, style: typography.bodyMediumSemiBold.copyWith(color: Colors.white)),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.chevronDown, size: 15, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
                        onPressed: () => _stepDay(1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Next Day',
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: _pickMonth,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.calendar, size: 15, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(_monthLabel, style: typography.bodyMediumSemiBold.copyWith(color: Colors.white)),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 15, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                const Gap(8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderSegmentTab(
                          label: 'All Shifts',
                          isSelected: _selectedShift == 'All',
                          onTap: () => setState(() {
                            _selectedShift = 'All';
                            _refreshKey++;
                          }),
                        ),
                        _HeaderSegmentTab(
                          label: 'Shift 1',
                          isSelected: _selectedShift == 'Shift-1',
                          onTap: () => setState(() {
                            _selectedShift = 'Shift-1';
                            _refreshKey++;
                          }),
                        ),
                        _HeaderSegmentTab(
                          label: 'Shift 2',
                          isSelected: _selectedShift == 'Shift-2',
                          onTap: () => setState(() {
                            _selectedShift = 'Shift-2';
                            _refreshKey++;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isStudent
                ? _StudentReportTab(
                    month: _monthKey,
                    date: _dayKey,
                    dateLabel: _dayLabel,
                    isDayWise: _viewMode == 'day',
                    instituteId: institute.id,
                    shift: _selectedShift,
                    refreshKey: _refreshKey,
                    onExportPdf: _exportAttendancePdf,
                    onExportExcel: _exportAttendanceExcel,
                    onDownload: () => _showDownloadOptions(context),
                  )
                : (_viewMode == 'day'
                    ? _TeacherDayReportTab(
                        date: _dayKey,
                        dateLabel: _dayLabel,
                        instituteId: institute.id,
                        shift: _selectedShift,
                        refreshKey: _refreshKey,
                        onExportPdf: _exportAttendancePdf,
                        onExportExcel: _exportAttendanceExcel,
                        onDownload: ([String? shift]) => _showDownloadOptions(context, presetShift: shift),
                      )
                    : _TeacherReportTab(
                        month: _monthKey,
                        instituteId: institute.id,
                        shift: _selectedShift,
                        refreshKey: _refreshKey,
                        onExportPdf: _exportAttendancePdf,
                        onExportExcel: _exportAttendanceExcel,
                        onDownload: ([String? shift]) => _showDownloadOptions(context, presetShift: shift),
                      )),
          ),
        ],
      ),
    );
  }
}

// ── Quick Export Button ───────────────────────────────────────────────────────

class _ExportQuickButton extends StatelessWidget {
  const _ExportQuickButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const Gap(5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// ── Student Report Tab ────────────────────────────────────────────────────────

class _StudentReportTab extends ConsumerStatefulWidget {
  const _StudentReportTab({
    required this.month,
    required this.date,
    required this.dateLabel,
    required this.isDayWise,
    required this.instituteId,
    this.shift = 'All',
    this.refreshKey = 0,
    this.onExportPdf,
    this.onExportExcel,
    this.onDownload,
  });

  final String month;
  final String date;
  final String dateLabel;
  final bool isDayWise;
  final String instituteId;
  final String shift;
  final int refreshKey;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onDownload;

  @override
  ConsumerState<_StudentReportTab> createState() => _StudentReportTabState();
}

class _StudentReportTabState extends ConsumerState<_StudentReportTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final params = _ReportParams(
      month: widget.month,
      date: widget.isDayWise ? widget.date : null,
      instituteId: widget.instituteId,
      type: 'student',
      shift: widget.shift,
      refreshKey: widget.refreshKey,
    );

    final reportAsync = ref.watch(_attendanceReportProvider(params));

    return reportAsync.when(
      data: (data) {
        final rawSummary = (data['summary'] as List?) ?? [];
        final summary = rawSummary.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        final rawStudentSummary = (data['studentSummary'] as List?) ?? [];
        final studentSummary = rawStudentSummary.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        final counts = (data['counts'] as Map<String, dynamic>?) ?? {};
        int totalRecords = counts['total'] as int? ?? (data['totalRecords'] as int? ?? 0);
        int totalPresent = counts['present'] as int? ?? 0;
        int totalAbsent = counts['absent'] as int? ?? 0;
        int totalLate = counts['late'] as int? ?? 0;
        int overallRate = counts['rate'] as int? ?? 0;

        if (!counts.containsKey('present')) {
          totalPresent = 0;
          totalAbsent = 0;
          totalLate = 0;
          for (final row in summary) {
            totalPresent += (row['present'] as int?) ?? 0;
            totalAbsent += (row['absent'] as int?) ?? 0;
            totalLate += (row['late'] as int?) ?? 0;
          }
          overallRate = totalRecords > 0 ? ((totalPresent / totalRecords) * 100).round() : 0;
        }

        if (summary.isEmpty && totalRecords == 0) {
          return _EmptyReport(
            message: widget.isDayWise
                ? 'No student attendance recorded for ${widget.dateLabel}.'
                : 'No student attendance recorded for ${widget.month}.',
          );
        }

        // Filtering classrooms
        final filteredClassrooms = summary.where((row) {
          final cName = (row['classroom'] as String? ?? '').toLowerCase();
          final rate = (row['rate'] as int?) ?? 0;
          final isMarked = row['isMarked'] as bool? ?? ((row['total'] as int? ?? 0) > 0);

          if (_searchQuery.isNotEmpty) {
            final matchesClass = cName.contains(_searchQuery.toLowerCase());
            final students = (row['students'] as List?) ?? [];
            final matchesStudent = students.any((s) {
              final sName = (s['fullName'] as String? ?? '').toLowerCase();
              final sAdm = (s['admissionNumber'] as String? ?? '').toLowerCase();
              return sName.contains(_searchQuery.toLowerCase()) || sAdm.contains(_searchQuery.toLowerCase());
            });
            if (!matchesClass && !matchesStudent) return false;
          }

          if (_selectedFilter == 'High (>=85%)' && rate < 85) return false;
          if (_selectedFilter == 'Avg (70-84%)' && (rate < 70 || rate >= 85)) return false;
          if (_selectedFilter == 'Low (<70%)' && rate >= 70) return false;
          if (_selectedFilter == 'Marked' && !isMarked) return false;
          if (_selectedFilter == 'Pending' && isMarked) return false;

          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Redesigned Hero KPI Card
            _StudentHeroCard(
              title: widget.isDayWise ? 'Daily Student Attendance' : 'Monthly Student Attendance',
              periodLabel: widget.isDayWise
                  ? widget.dateLabel
                  : DateFormat('MMMM yyyy').format(DateTime.parse('${widget.month}-01')),
              total: totalRecords,
              present: totalPresent,
              late: totalLate,
              absent: totalAbsent,
              rate: overallRate,
            ),
            const Gap(16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by classroom or student name...',
                  hintStyle: typography.bodyMedium.copyWith(color: colors.textSecondary.withValues(alpha: 0.7)),
                  prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const Gap(12),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${summary.length})',
                    isSelected: _selectedFilter == 'All',
                    color: colors.primary,
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'High (>=85%)',
                    isSelected: _selectedFilter == 'High (>=85%)',
                    color: Colors.green,
                    onTap: () => setState(() => _selectedFilter = 'High (>=85%)'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Avg (70-84%)',
                    isSelected: _selectedFilter == 'Avg (70-84%)',
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedFilter = 'Avg (70-84%)'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Low (<70%)',
                    isSelected: _selectedFilter == 'Low (<70%)',
                    color: Colors.red,
                    onTap: () => setState(() => _selectedFilter = 'Low (<70%)'),
                  ),
                  if (widget.isDayWise) ...[
                    const Gap(8),
                    _FilterChip(
                      label: 'Marked',
                      isSelected: _selectedFilter == 'Marked',
                      color: Colors.teal,
                      onTap: () => setState(() => _selectedFilter = 'Marked'),
                    ),
                    const Gap(8),
                    _FilterChip(
                      label: 'Pending',
                      isSelected: _selectedFilter == 'Pending',
                      color: Colors.blueGrey,
                      onTap: () => setState(() => _selectedFilter = 'Pending'),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(16),

            // Header for Classroom list with Download Actions
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classrooms (${filteredClassrooms.length})',
                      style: typography.bodyMediumSemiBold,
                    ),
                    Text(
                      'Tap to inspect students',
                      style: typography.caption.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.onDownload != null)
                  _ExportQuickButton(
                    label: 'Download',
                    icon: LucideIcons.download,
                    color: context.colors.primary,
                    tooltip: 'Download report (choose shift & format)',
                    onTap: widget.onDownload!,
                  )
                else ...[
                  if (widget.onExportPdf != null) ...[
                    _ExportQuickButton(
                      label: 'PDF',
                      icon: LucideIcons.fileText,
                      color: Colors.red.shade700,
                      tooltip: 'Download PDF Report',
                      onTap: widget.onExportPdf!,
                    ),
                    const Gap(6),
                  ],
                  if (widget.onExportExcel != null)
                    _ExportQuickButton(
                      label: 'Excel',
                      icon: LucideIcons.table,
                      color: Colors.green.shade800,
                      tooltip: 'Download Excel Sheet',
                      onTap: widget.onExportExcel!,
                    ),
                ],
              ],
            ),
            const Gap(10),

            if (filteredClassrooms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No classrooms match your filter.',
                    style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...filteredClassrooms.map((row) => _StudentClassroomCard(
                    row: row,
                    isDayWise: widget.isDayWise,
                    dateLabel: widget.isDayWise ? widget.dateLabel : widget.month,
                    onTap: () => _openClassroomSheet(context, row, studentSummary),
                  )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
    );
  }

  void _openClassroomSheet(
    BuildContext context,
    Map<String, dynamic> classRow,
    List<Map<String, dynamic>> allStudentSummaries,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClassroomStudentsSheet(
        classroomData: classRow,
        isDayWise: widget.isDayWise,
        periodLabel: widget.isDayWise ? widget.dateLabel : widget.month,
        month: widget.month,
        instituteId: widget.instituteId,
        allStudentSummaries: allStudentSummaries,
      ),
    );
  }
}

class _StudentHeroCard extends StatelessWidget {
  const _StudentHeroCard({
    required this.title,
    required this.periodLabel,
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
    required this.rate,
  });

  final String title;
  final String periodLabel;
  final int total;
  final int present;
  final int late;
  final int absent;
  final int rate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final double pRatio = total > 0 ? (present / total).clamp(0.0, 1.0) : 0;
    final double lRatio = total > 0 ? (late / total).clamp(0.0, 1.0) : 0;
    final double aRatio = total > 0 ? (absent / total).clamp(0.0, 1.0) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF0F4A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 24),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: typography.bodySmall.copyWith(color: Colors.white70)),
                    Text(periodLabel, style: typography.bodyLargeSemiBold.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rate >= 80 ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                      size: 14,
                      color: Colors.white,
                    ),
                    const Gap(6),
                    Text(
                      '$rate% Attendance',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),

          // Proportional Multi-Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              color: Colors.white.withValues(alpha: 0.15),
              child: Row(
                children: [
                  if (pRatio > 0)
                    Flexible(flex: (pRatio * 1000).toInt(), child: Container(color: Colors.greenAccent)),
                  if (lRatio > 0)
                    Flexible(flex: (lRatio * 1000).toInt(), child: Container(color: Colors.amberAccent)),
                  if (aRatio > 0)
                    Flexible(flex: (aRatio * 1000).toInt(), child: Container(color: const Color(0xFFFF8A80))),
                ],
              ),
            ),
          ),
          const Gap(18),

          // 4 Metric Tiles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricTile('Total', total.toString(), LucideIcons.users, Colors.white),
              _metricTile('Present', present.toString(), LucideIcons.userCheck, Colors.greenAccent),
              _metricTile('Late', late.toString(), LucideIcons.clock, Colors.amberAccent),
              _metricTile('Absent', absent.toString(), LucideIcons.userX, const Color(0xFFFF8A80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.9)),
            const Gap(5),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StudentClassroomCard extends StatelessWidget {
  const _StudentClassroomCard({
    required this.row,
    required this.isDayWise,
    required this.dateLabel,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final bool isDayWise;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final classroom = row['classroom'] as String? ?? 'Unknown';
    final shift = row['shift'] as String? ?? 'Shift-1';
    final present = (row['present'] as int?) ?? 0;
    final absent = (row['absent'] as int?) ?? 0;
    final late = (row['late'] as int?) ?? 0;
    final total = (row['total'] as int?) ?? 0;
    final rate = (row['rate'] as int?) ?? 0;
    final isMarked = row['isMarked'] as bool? ?? (total > 0);

    final Color rateColor = rate >= 85
        ? Colors.green
        : (rate >= 70 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Class initial avatar + name + status badge + rate chip
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        classroom.isNotEmpty ? classroom.substring(0, classroom.length >= 3 ? 3 : classroom.length) : 'CLS',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(classroom, style: typography.bodyLargeSemiBold),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.border.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  shift,
                                  style: typography.caption.copyWith(color: colors.textSecondary, fontSize: 10),
                                ),
                              ),
                              if (isDayWise) ...[
                                const Gap(6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isMarked
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.orange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isMarked ? LucideIcons.check : LucideIcons.clock,
                                        size: 10,
                                        color: isMarked ? Colors.green : Colors.orange,
                                      ),
                                      const Gap(3),
                                      Text(
                                        isMarked ? 'Marked' : 'Pending',
                                        style: TextStyle(
                                          color: isMarked ? Colors.green : Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Gap(2),
                          Text(
                            '$total Enrolled / Tracked',
                            style: typography.caption.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: rateColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: rateColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '$rate%',
                        style: TextStyle(color: rateColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Gap(14),

                // Linear progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total > 0 ? (present / total).clamp(0.0, 1.0) : 0,
                    backgroundColor: colors.border.withValues(alpha: 0.6),
                    color: rateColor,
                    minHeight: 7,
                  ),
                ),
                const Gap(12),

                // Metrics pills row + "View Students" button
                Row(
                  children: [
                    _countBadge('Present', present, Colors.green),
                    const Gap(6),
                    if (late > 0) ...[
                      _countBadge('Late', late, Colors.orange),
                      const Gap(6),
                    ],
                    _countBadge('Absent', absent, Colors.red),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Students',
                          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Gap(4),
                        Icon(LucideIcons.chevronRight, size: 14, color: colors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ClassroomStudentsSheet extends StatefulWidget {
  const _ClassroomStudentsSheet({
    required this.classroomData,
    required this.isDayWise,
    required this.periodLabel,
    required this.month,
    required this.instituteId,
    required this.allStudentSummaries,
  });

  final Map<String, dynamic> classroomData;
  final bool isDayWise;
  final String periodLabel;
  final String month;
  final String instituteId;
  final List<Map<String, dynamic>> allStudentSummaries;

  @override
  State<_ClassroomStudentsSheet> createState() => _ClassroomStudentsSheetState();
}

class _ClassroomStudentsSheetState extends State<_ClassroomStudentsSheet> {
  final TextEditingController _studentSearchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All';
  String _sheetSubMode = 'totals'; // 'totals' (Monthly Totals) or 'daily' (Date Breakdown)
  String? _selectedBreakdownDate;

  @override
  void dispose() {
    _studentSearchCtrl.dispose();
    super.dispose();
  }

  void _openStudentHistory(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StudentAttendanceHistorySheet(
        student: student,
        month: widget.month,
        instituteId: widget.instituteId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final className = widget.classroomData['classroom'] as String? ?? 'Classroom';
    final rate = (widget.classroomData['rate'] as int?) ?? 0;
    final present = (widget.classroomData['present'] as int?) ?? 0;
    final absent = (widget.classroomData['absent'] as int?) ?? 0;
    final late = (widget.classroomData['late'] as int?) ?? 0;

    // Enrolled children in that specific class (prioritizing backend populated enrolled students)
    List<Map<String, dynamic>> students = [];
    final classStudentsRaw = (widget.classroomData['students'] as List?) ?? [];
    if (classStudentsRaw.isNotEmpty) {
      students = classStudentsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      students = widget.allStudentSummaries
          .where((s) => (s['classroom']?.toString() ?? '') == className)
          .toList();
    }

    // Extract all distinct dates in this classroom for the month
    final Set<String> distinctDates = {};
    for (final s in students) {
      final days = (s['days'] as List?) ?? [];
      for (final d in days) {
        if (d is Map && d['date'] != null) {
          final dtStr = d['date'].toString();
          final key = dtStr.length >= 10 ? dtStr.substring(0, 10) : dtStr;
          distinctDates.add(key);
        }
      }
    }
    final sortedDates = distinctDates.toList()..sort();
    if (_selectedBreakdownDate == null && sortedDates.isNotEmpty) {
      _selectedBreakdownDate = sortedDates.last;
    }

    // Filter students by search and status
    final filtered = students.where((s) {
      final name = (s['fullName'] as String? ?? '').toLowerCase();
      final adm = (s['admissionNumber'] as String? ?? '').toLowerCase();
      if (_search.isNotEmpty && !name.contains(_search) && !adm.contains(_search)) {
        return false;
      }
      if (_statusFilter != 'All') {
        if (widget.isDayWise) {
          final status = s['status'] as String? ?? '';
          if (status != _statusFilter) return false;
        } else if (_sheetSubMode == 'daily' && _selectedBreakdownDate != null) {
          final dayRecord = (s['days'] as List?)?.firstWhere(
            (d) => (d is Map) && (d['date']?.toString() ?? '').startsWith(_selectedBreakdownDate!),
            orElse: () => null,
          );
          final status = dayRecord != null ? (dayRecord['status']?.toString() ?? 'Absent') : 'Pending';
          if (status != _statusFilter) return false;
        } else {
          final sAbsent = (s['absent'] as int?) ?? 0;
          if (_statusFilter == 'Absent' && sAbsent == 0) return false;
          final sPresent = (s['present'] as int?) ?? 0;
          if (_statusFilter == 'Present' && sPresent == 0) return false;
        }
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Gap(10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Gap(12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.school, color: colors.primary, size: 22),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$className Attendance', style: typography.h4),
                        Text(
                          widget.isDayWise
                              ? widget.periodLabel
                              : (_sheetSubMode == 'daily' && _selectedBreakdownDate != null
                                  ? 'Date: $_selectedBreakdownDate • ${widget.periodLabel}'
                                  : widget.periodLabel),
                          style: typography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$rate% Rate',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const Gap(6),
                  Tooltip(
                    message: 'Download Classroom Attendance',
                    child: InkWell(
                      onTap: _exportClassPdf,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.download, size: 16, color: colors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            // Mode Toggle for Monthly mode: Monthly Totals vs Date Breakdown
            if (!widget.isDayWise) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _sheetSubMode = 'totals';
                            _statusFilter = 'All';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _sheetSubMode == 'totals' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _sheetSubMode == 'totals'
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                                  : null,
                            ),
                            child: Text(
                              'Monthly Totals',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _sheetSubMode == 'totals' ? FontWeight.w700 : FontWeight.w500,
                                color: _sheetSubMode == 'totals' ? colors.primary : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _sheetSubMode = 'daily';
                            _statusFilter = 'All';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _sheetSubMode == 'daily' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _sheetSubMode == 'daily'
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                                  : null,
                            ),
                            child: Text(
                              'Date Breakdown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _sheetSubMode == 'daily' ? FontWeight.w700 : FontWeight.w500,
                                color: _sheetSubMode == 'daily' ? colors.primary : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(10),
            ],

            // Date picker chips when in Date Breakdown mode
            if (!widget.isDayWise && _sheetSubMode == 'daily') ...[
              if (sortedDates.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: sortedDates.map((dStr) {
                      final isSel = _selectedBreakdownDate == dStr;
                      DateTime? dt = DateTime.tryParse(dStr);
                      final label = dt != null ? DateFormat('d MMM (E)').format(dt) : dStr;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedBreakdownDate = dStr),
                          selectedColor: colors.primary,
                          backgroundColor: colors.border.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : colors.textPrimary,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'No daily records recorded for this classroom in ${widget.month}.',
                    style: typography.caption.copyWith(color: colors.textSecondary),
                  ),
                ),
              const Gap(10),
            ],

            // Mini stats summary row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _sheetMetric('Total Enrolled', students.length.toString(), colors.textPrimary),
                    _sheetMetric('Present', present.toString(), Colors.green),
                    if (late > 0) _sheetMetric('Late', late.toString(), Colors.orange),
                    _sheetMetric('Absent', absent.toString(), Colors.red),
                  ],
                ),
              ),
            ),
            const Gap(12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _studentSearchCtrl,
                  onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search student by name or admission no...',
                    hintStyle: typography.caption.copyWith(color: colors.textSecondary),
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.textSecondary),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14),
                            onPressed: () {
                              _studentSearchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const Gap(10),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _chip('All (${students.length})', 'All', colors.primary),
                  const Gap(6),
                  _chip('Present', 'Present', Colors.green),
                  const Gap(6),
                  _chip('Absent', 'Absent', Colors.red),
                ],
              ),
            ),
            const Gap(8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Tip: Tap any student to view detailed attendance history.',
                    style: typography.caption.copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Gap(6),

            // List of students
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No students found.',
                        style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        final name = s['fullName'] as String? ?? 'Unknown';
                        final adm = s['admissionNumber'] as String? ?? '';
                        final phone = s['parentContact'] as String?;
                        final shift = s['shift'] as String?;

                        if (widget.isDayWise) {
                          final status = s['status'] as String? ?? 'Absent';
                          final remarks = s['remarks'] as String?;
                          final Color statusColor = status == 'Present'
                              ? Colors.green
                              : (status == 'Late' ? Colors.orange : (status == 'Pending' ? Colors.grey : Colors.red));

                          return InkWell(
                            onTap: () => _openStudentHistory(s),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: statusColor.withValues(alpha: 0.12),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(child: Text(name, style: typography.bodyMediumSemiBold)),
                                            if (shift != null && shift.isNotEmpty) ...[
                                              const Gap(6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: colors.primary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  shift == 'Shift-1' ? 'Shift 1' : (shift == 'Shift-2' ? 'Shift 2' : shift),
                                                  style: TextStyle(color: colors.primary, fontSize: 9, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const Gap(2),
                                        Row(
                                          children: [
                                            Text(adm, style: typography.caption.copyWith(color: colors.textSecondary)),
                                            if (phone != null && phone.isNotEmpty) ...[
                                              const Gap(8),
                                              Text('• $phone', style: typography.caption.copyWith(color: colors.textSecondary)),
                                            ],
                                          ],
                                        ),
                                        if (remarks != null && remarks.isNotEmpty) ...[
                                          const Gap(2),
                                          Text('Note: $remarks', style: typography.caption.copyWith(color: Colors.orange)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                  const Gap(8),
                                  Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary.withValues(alpha: 0.6)),
                                ],
                              ),
                            ),
                          );
                        } else if (_sheetSubMode == 'daily' && _selectedBreakdownDate != null) {
                          // Date breakdown within month
                          final dayRecord = (s['days'] as List?)?.firstWhere(
                            (d) => (d is Map) && (d['date']?.toString() ?? '').startsWith(_selectedBreakdownDate!),
                            orElse: () => null,
                          );
                          final status = dayRecord != null ? (dayRecord['status']?.toString() ?? 'Absent') : 'Pending';
                          final remarks = dayRecord != null ? (dayRecord['remarks']?.toString()) : null;
                          final Color statusColor = status == 'Present'
                              ? Colors.green
                              : (status == 'Late' ? Colors.orange : (status == 'Pending' ? Colors.grey : Colors.red));

                          return InkWell(
                            onTap: () => _openStudentHistory(s),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: statusColor.withValues(alpha: 0.12),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(child: Text(name, style: typography.bodyMediumSemiBold)),
                                            if (shift != null && shift.isNotEmpty) ...[
                                              const Gap(6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: colors.primary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  shift == 'Shift-1' ? 'Shift 1' : (shift == 'Shift-2' ? 'Shift 2' : shift),
                                                  style: TextStyle(color: colors.primary, fontSize: 9, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const Gap(2),
                                        Text(adm, style: typography.caption.copyWith(color: colors.textSecondary)),
                                        if (remarks != null && remarks.isNotEmpty) ...[
                                          const Gap(2),
                                          Text('Note: $remarks', style: typography.caption.copyWith(color: Colors.orange)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                  const Gap(8),
                                  Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary.withValues(alpha: 0.6)),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // Monthly view item
                          final sPresent = (s['present'] as int?) ?? 0;
                          final sAbsent = (s['absent'] as int?) ?? 0;
                          final sTotal = (s['total'] as int?) ?? 0;
                          final sRate = (s['rate'] as int?) ?? 0;

                          return InkWell(
                            onTap: () => _openStudentHistory(s),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(child: Text(name, style: typography.bodyMediumSemiBold)),
                                            if (shift != null && shift.isNotEmpty) ...[
                                              const Gap(6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: colors.primary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  shift == 'Shift-1' ? 'Shift 1' : (shift == 'Shift-2' ? 'Shift 2' : shift),
                                                  style: TextStyle(color: colors.primary, fontSize: 9, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const Gap(2),
                                        Text(adm, style: typography.caption.copyWith(color: colors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$sRate%',
                                        style: TextStyle(
                                          color: sRate >= 80 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'P: $sPresent • A: $sAbsent / $sTotal d',
                                        style: typography.caption.copyWith(color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const Gap(8),
                                  Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary.withValues(alpha: 0.6)),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportClassPdf() async {
    final className = widget.classroomData['classroom'] as String? ?? 'Classroom';
    List<Map<String, dynamic>> rawList = [];
    final classStudentsRaw = (widget.classroomData['students'] as List?) ?? [];
    if (classStudentsRaw.isNotEmpty) {
      rawList = classStudentsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      rawList = widget.allStudentSummaries
          .where((s) => (s['classroom']?.toString() ?? '') == className)
          .toList();
    }

    if (rawList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student records to export for this class.')),
      );
      return;
    }

    final present = (widget.classroomData['present'] as int?) ?? 0;
    final absent = (widget.classroomData['absent'] as int?) ?? 0;
    final late = (widget.classroomData['late'] as int?) ?? 0;
    final rate = (widget.classroomData['rate'] as int?) ?? 0;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('$className Attendance Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Date / Period: ${widget.periodLabel}', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Text('Total Enrolled: ${rawList.length} | Present: $present | Absent: $absent | Late: $late | Attendance Rate: $rate%',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: widget.isDayWise
                ? ['Admn No', 'Student Name', 'Status', 'Remarks', 'Parent Contact']
                : ['Admn No', 'Student Name', 'Present', 'Absent', 'Late', 'Total', 'Rate'],
            data: rawList.map((s) {
              if (widget.isDayWise) {
                return [
                  s['admissionNumber']?.toString() ?? '',
                  s['fullName']?.toString() ?? '',
                  s['status']?.toString() ?? '',
                  s['remarks']?.toString() ?? '—',
                  s['parentContact']?.toString() ?? '—',
                ];
              } else {
                return [
                  s['admissionNumber']?.toString() ?? '',
                  s['fullName']?.toString() ?? '',
                  s['present']?.toString() ?? '0',
                  s['absent']?.toString() ?? '0',
                  s['late']?.toString() ?? '0',
                  s['total']?.toString() ?? '0',
                  '${s['rate'] ?? 0}%',
                ];
              }
            }).toList(),
          ),
        ],
      ),
    );

    final safeClassName = className.replaceAll(' ', '_');
    final fname = '${safeClassName}_attendance_${widget.periodLabel.replaceAll(' ', '_')}.pdf';
    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) => bytes, name: fname);
    } else {
      final box = context.findRenderObject() as RenderBox?;
      final origin = (box != null && box.hasSize)
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 100, 100);
      await Printing.sharePdf(bytes: bytes, filename: fname, bounds: origin);
    }
  }

  Widget _sheetMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _chip(String text, String keyVal, Color color) {
    final isSelected = _statusFilter == keyVal;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = keyVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Student Attendance History Sheet ─────────────────────────────────────────

class _StudentAttendanceHistorySheet extends ConsumerStatefulWidget {
  const _StudentAttendanceHistorySheet({
    required this.student,
    required this.month,
    required this.instituteId,
  });

  final Map<String, dynamic> student;
  final String month;
  final String instituteId;

  @override
  ConsumerState<_StudentAttendanceHistorySheet> createState() => _StudentAttendanceHistorySheetState();
}

class _StudentAttendanceHistorySheetState extends ConsumerState<_StudentAttendanceHistorySheet> {
  late String _activeMonth = widget.month;
  String _historyFilter = 'All';

  void _stepMonth(int delta) {
    final parts = _activeMonth.split('-');
    if (parts.length == 2) {
      final y = int.tryParse(parts[0]) ?? DateTime.now().year;
      final m = int.tryParse(parts[1]) ?? DateTime.now().month;
      final dt = DateTime(y, m + delta);
      setState(() => _activeMonth = DateFormat('yyyy-MM').format(dt));
    }
  }

  Future<void> _pickMonth() async {
    final parts = _activeMonth.split('-');
    final y = parts.length == 2 ? int.tryParse(parts[0]) ?? DateTime.now().year : DateTime.now().year;
    final m = parts.length == 2 ? int.tryParse(parts[1]) ?? DateTime.now().month : DateTime.now().month;
    final picked = await CustomMonthPicker.show(
      context: context,
      initialDate: DateTime(y, m),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _activeMonth = DateFormat('yyyy-MM').format(picked));
    }
  }

  Future<void> _exportPdf(
    Map<String, dynamic> studentMeta,
    Map<String, dynamic> summary,
    List<Map<String, dynamic>> days,
  ) async {
    final pdf = pw.Document();
    final name = studentMeta['fullName']?.toString() ?? 'Student';
    final adm = studentMeta['admissionNumber']?.toString() ?? '';
    final grade = studentMeta['grade']?.toString() ?? '';
    final shift = studentMeta['shift']?.toString() ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Student Attendance History Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Month: $_activeMonth', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Name: $name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Admission No: $adm'),
                pw.Text('Class: $grade'),
                if (shift.isNotEmpty) pw.Text('Shift: $shift'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Present: ${summary['present'] ?? 0} | Absent: ${summary['absent'] ?? 0} | Late: ${summary['late'] ?? 0} | Attendance Rate: ${summary['rate'] ?? 0}%',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Day', 'Status', 'Remarks'],
            data: days.map((d) {
              DateTime? dt = DateTime.tryParse(d['date']?.toString() ?? '');
              final dateStr = dt != null ? DateFormat('dd MMM yyyy').format(dt) : (d['date']?.toString() ?? '');
              final dayStr = dt != null ? DateFormat('EEEE').format(dt) : '';
              return [
                dateStr,
                dayStr,
                d['status']?.toString() ?? '',
                d['remarks']?.toString() ?? '—',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final safeName = name.replaceAll(' ', '_');
    final fname = '${safeName}_attendance_$_activeMonth.pdf';
    final bytes = await pdf.save();
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) => bytes, name: fname);
    } else {
      final box = context.findRenderObject() as RenderBox?;
      final origin = (box != null && box.hasSize)
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 100, 100);
      await Printing.sharePdf(bytes: bytes, filename: fname, bounds: origin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final studentId = widget.student['_id']?.toString() ??
        widget.student['id']?.toString() ??
        widget.student['studentId']?.toString() ??
        '';

    final name = widget.student['fullName']?.toString() ?? 'Student';
    final adm = widget.student['admissionNumber']?.toString() ?? '';
    final grade = widget.student['grade']?.toString() ?? widget.student['classroom']?.toString() ?? '';
    final phone = widget.student['parentContact']?.toString();
    final shift = widget.student['shift']?.toString();

    final asyncReport = ref.watch(_studentReportProvider(_StudentDaysParams(
      studentId: studentId,
      month: _activeMonth,
      instituteId: widget.instituteId,
    )));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Gap(10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Gap(12),

            // Student profile header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(name, style: typography.h4)),
                            if (shift != null && shift.isNotEmpty) ...[
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  shift == 'Shift-1' ? 'Shift 1' : (shift == 'Shift-2' ? 'Shift 2' : shift),
                                  style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Text(adm, style: typography.caption.copyWith(color: colors.textSecondary)),
                            if (grade.isNotEmpty) ...[
                              const Gap(6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colors.border.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(grade, style: typography.caption.copyWith(fontWeight: FontWeight.w600)),
                              ),
                            ],
                            if (phone != null && phone.isNotEmpty) ...[
                              const Gap(8),
                              Icon(LucideIcons.phone, size: 12, color: colors.textSecondary),
                              const Gap(4),
                              Text(phone, style: typography.caption.copyWith(color: colors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(14),

            // Month navigation & PDF export
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 18),
                          onPressed: () => _stepMonth(-1),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        InkWell(
                          onTap: _pickMonth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 14),
                                const Gap(6),
                                Text(
                                  _activeMonth,
                                  style: typography.bodyMediumSemiBold,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight, size: 18),
                          onPressed: () => _stepMonth(1),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  asyncReport.maybeWhen(
                    data: (data) {
                      final meta = (data['student'] as Map<String, dynamic>?) ?? widget.student;
                      final summary = (data['summary'] as Map<String, dynamic>?) ?? {};
                      final daysRaw = (data['days'] as List?) ?? [];
                      final days = daysRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
                      return ElevatedButton.icon(
                        onPressed: () => _exportPdf(meta, summary, days),
                        icon: const Icon(LucideIcons.download, size: 14),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Gap(12),

            Expanded(
              child: asyncReport.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(friendlyErrorMessage(e), textAlign: TextAlign.center),
                  ),
                ),
                data: (data) {
                  final summary = (data['summary'] as Map<String, dynamic>?) ?? {};
                  final daysRaw = (data['days'] as List?) ?? [];
                  final days = daysRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

                  final int present = summary['present'] as int? ?? 0;
                  final int absent = summary['absent'] as int? ?? 0;
                  final int late = summary['late'] as int? ?? 0;
                  final int total = summary['total'] as int? ?? 0;
                  final int rate = summary['rate'] as int? ?? 0;

                  final filteredDays = days.where((d) {
                    if (_historyFilter == 'All') return true;
                    return (d['status']?.toString() ?? '') == _historyFilter;
                  }).toList();

                  return Column(
                    children: [
                      // Summary metric cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(child: _metricBox('Days', total.toString(), colors.textPrimary, colors)),
                            const Gap(8),
                            Expanded(child: _metricBox('Present', present.toString(), Colors.green, colors)),
                            const Gap(8),
                            if (late > 0) ...[
                              Expanded(child: _metricBox('Late', late.toString(), Colors.orange, colors)),
                              const Gap(8),
                            ],
                            Expanded(child: _metricBox('Absent', absent.toString(), Colors.red, colors)),
                            const Gap(8),
                            Expanded(
                              child: _metricBox(
                                'Rate',
                                '$rate%',
                                rate >= 80 ? Colors.green : Colors.red,
                                colors,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),

                      // Filter chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _filterChip('All (${days.length})', 'All', colors.primary),
                            const Gap(6),
                            _filterChip('Present ($present)', 'Present', Colors.green),
                            const Gap(6),
                            _filterChip('Absent ($absent)', 'Absent', Colors.red),
                          ],
                        ),
                      ),
                      const Gap(10),

                      // Chronological list of dates
                      Expanded(
                        child: filteredDays.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    days.isEmpty
                                        ? 'No attendance records found for $_activeMonth.'
                                        : 'No records matching "$_historyFilter".',
                                    style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                itemCount: filteredDays.length,
                                separatorBuilder: (_, _) => Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),
                                itemBuilder: (_, i) {
                                  final d = filteredDays[i];
                                  final dt = DateTime.tryParse(d['date']?.toString() ?? '');
                                  final status = d['status']?.toString() ?? '';
                                  final remarks = d['remarks']?.toString();
                                  final dateFormatted = dt != null ? DateFormat('EEEE, dd MMM yyyy').format(dt) : (d['date']?.toString() ?? '');

                                  final Color c;
                                  final IconData ic;
                                  switch (status) {
                                    case 'Present':
                                      c = Colors.green;
                                      ic = LucideIcons.checkCircle2;
                                      break;
                                    case 'Late':
                                      c = Colors.orange;
                                      ic = LucideIcons.clock;
                                      break;
                                    case 'Absent':
                                    default:
                                      c = Colors.red;
                                      ic = LucideIcons.xCircle;
                                      break;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: c.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(ic, color: c, size: 16),
                                        ),
                                        const Gap(12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(dateFormatted, style: typography.bodyMediumSemiBold),
                                              if (remarks != null && remarks.isNotEmpty) ...[
                                                const Gap(2),
                                                Text('Reason: $remarks', style: typography.caption.copyWith(color: Colors.orange.shade800)),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: c.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricBox(String label, String value, Color color, dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const Gap(2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _filterChip(String text, String keyVal, Color color) {
    final isSelected = _historyFilter == keyVal;
    return GestureDetector(
      onTap: () => setState(() => _historyFilter = keyVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Teacher Monthly Hero Card ─────────────────────────────────────────────────

class _TeacherHeroCard extends StatelessWidget {
  const _TeacherHeroCard({
    required this.title,
    required this.periodLabel,
    required this.totalStaff,
    required this.present,
    required this.late,
    required this.absent,
    required this.rate,
    this.presentLabel = 'Present Days',
    this.lateLabel = 'Late Days',
    this.absentLabel = 'Absent Days',
    this.staffLabel = 'Staff Count',
    this.rateLabel = 'Attendance',
  });

  final String title;
  final String periodLabel;
  final int totalStaff;
  final int present;
  final int late;
  final int absent;
  final int rate;
  final String presentLabel;
  final String lateLabel;
  final String absentLabel;
  final String staffLabel;
  final String rateLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final total = present + late + absent;
    final double pRatio = total > 0 ? (present / total).clamp(0.0, 1.0) : 0;
    final double lRatio = total > 0 ? (late / total).clamp(0.0, 1.0) : 0;
    final double aRatio = total > 0 ? (absent / total).clamp(0.0, 1.0) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF0F4A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.briefcase, color: Colors.white, size: 24),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: typography.bodySmall.copyWith(color: Colors.white70)),
                    Text(periodLabel, style: typography.bodyLargeSemiBold.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rate >= 80 ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                      size: 14,
                      color: Colors.white,
                    ),
                    const Gap(6),
                    Text(
                      '$rate% $rateLabel',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              color: Colors.white.withValues(alpha: 0.15),
              child: Row(
                children: [
                  if (pRatio > 0)
                    Flexible(flex: (pRatio * 1000).toInt(), child: Container(color: Colors.greenAccent)),
                  if (lRatio > 0)
                    Flexible(flex: (lRatio * 1000).toInt(), child: Container(color: Colors.amberAccent)),
                  if (aRatio > 0)
                    Flexible(flex: (aRatio * 1000).toInt(), child: Container(color: const Color(0xFFFF8A80))),
                ],
              ),
            ),
          ),
          const Gap(18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricTile(staffLabel, totalStaff.toString(), LucideIcons.users, Colors.white),
              _metricTile(presentLabel, present.toString(), LucideIcons.userCheck, Colors.greenAccent),
              _metricTile(lateLabel, late.toString(), LucideIcons.clock, Colors.amberAccent),
              _metricTile(absentLabel, absent.toString(), LucideIcons.userX, const Color(0xFFFF8A80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const Gap(5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Teacher Report Tab ────────────────────────────────────────────────────────

class _TeacherReportTab extends ConsumerStatefulWidget {
  const _TeacherReportTab({
    required this.month,
    required this.instituteId,
    this.shift,
    this.refreshKey = 0,
    this.onExportPdf,
    this.onExportExcel,
    this.onDownload,
  });
  final String month;
  final String instituteId;
  final String? shift;
  final int refreshKey;
  final void Function([String? shift])? onExportPdf;
  final void Function([String? shift])? onExportExcel;
  final void Function([String? shift])? onDownload;

  @override
  ConsumerState<_TeacherReportTab> createState() => _TeacherReportTabState();
}

class _TeacherReportTabState extends ConsumerState<_TeacherReportTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedShift = 'All';
  String _selectedRateFilter = 'All';

  @override
  void initState() {
    super.initState();
    _syncShift(widget.shift);
  }

  @override
  void didUpdateWidget(covariant _TeacherReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shift != widget.shift) {
      _syncShift(widget.shift);
    }
  }

  void _syncShift(String? s) {
    if (s == 'Shift-1' || s == 'Shift 1') {
      _selectedShift = 'Shift 1';
    } else if (s == 'Shift-2' || s == 'Shift 2') {
      _selectedShift = 'Shift 2';
    } else if (s == 'Dual Shift') {
      _selectedShift = 'Dual Shift';
    } else {
      _selectedShift = 'All';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Backend-format shift ('Shift-1'/'Shift-2') to scope a teacher's drill-down to,
  // taken from the active single-shift filter. Null for 'All'/'Dual Shift'
  // (dual-shift teachers keep both shifts' days in the detail view).
  String? get _drillShift {
    if (_selectedShift == 'Shift 1') return 'Shift-1';
    if (_selectedShift == 'Shift 2') return 'Shift-2';
    return null;
  }

  bool _matchesShift(Map<String, dynamic> r, String shiftFilter) {
    if (shiftFilter == 'All') return true;
    final shifts = (r['shifts'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final isDual = r['isDualShift'] == true || shifts.any((s) => s.contains('Dual')) || shifts.length > 1;
    if (shiftFilter == 'Dual Shift') return isDual;
    if (shiftFilter == 'Shift 1' || shiftFilter == 'Shift-1') {
      return shifts.any((s) => s.contains('Shift-1') || s.contains('Shift 1'));
    }
    if (shiftFilter == 'Shift 2' || shiftFilter == 'Shift-2') {
      return shifts.any((s) => s.contains('Shift-2') || s.contains('Shift 2'));
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final params = _ReportParams(
      month: widget.month,
      instituteId: widget.instituteId,
      type: 'teacher',
      shift: widget.shift,
      refreshKey: widget.refreshKey,
    );
    final reportAsync = ref.watch(_attendanceReportProvider(params));
    return reportAsync.when(
      data: (data) {
        final rawSummary = (data['summary'] as List?) ?? [];
        final summary = rawSummary.where((row) {
          final r = row as Map<String, dynamic>;
          final name = r['fullName'] as String?;
          return name != null && name.isNotEmpty && name.toLowerCase() != 'unknown';
        }).map((e) => Map<String, dynamic>.from(e as Map)).toList();

        if (summary.isEmpty) {
          return _EmptyReport(message: 'No teacher attendance recorded for ${widget.month}.');
        }

        // Aggregate stats across all teachers for the month
        int totalTeachers = summary.length;
        int totalPresent = 0;
        int totalLate = 0;
        int totalAbsent = 0;
        int totalDays = 0;

        for (final r in summary) {
          totalPresent += (r['present'] as int?) ?? 0;
          totalLate += (r['late'] as int?) ?? 0;
          totalAbsent += (r['absent'] as int?) ?? 0;
          totalDays += (r['total'] as int?) ?? 0;
        }
        final overallRate = totalDays > 0 ? ((totalPresent / totalDays) * 100).round() : 0;

        // Shift distribution counts
        final shift1Count = summary.where((r) => _matchesShift(r, 'Shift 1')).length;
        final shift2Count = summary.where((r) => _matchesShift(r, 'Shift 2')).length;
        final dualCount = summary.where((r) => _matchesShift(r, 'Dual Shift')).length;

        // Filtered teachers list
        final filtered = summary.where((row) {
          if (!_matchesShift(row, _selectedShift)) return false;

          final rate = (row['rate'] as int?) ?? 0;
          if (_selectedRateFilter == 'High (>=85%)' && rate < 85) return false;
          if (_selectedRateFilter == 'Avg (70-84%)' && (rate < 70 || rate >= 85)) return false;
          if (_selectedRateFilter == 'Low (<70%)' && rate >= 70) return false;

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final name = (row['fullName'] as String? ?? '').toLowerCase();
            final emp = (row['employeeId'] as String? ?? '').toLowerCase();
            final classes = (row['classes'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
            final subjects = (row['subjects'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
            final matchesClass = classes.any((c) => c.contains(q));
            final matchesSubject = subjects.any((s) => s.contains(q));
            if (!name.contains(q) && !emp.contains(q) && !matchesClass && !matchesSubject) {
              return false;
            }
          }

          return true;
        }).toList();

        String formattedMonth;
        try {
          formattedMonth = DateFormat('MMMM yyyy').format(DateTime.parse('${widget.month}-01'));
        } catch (_) {
          formattedMonth = widget.month;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // High-context Hero summary card
            _TeacherHeroCard(
              title: 'Teacher Monthly Attendance',
              periodLabel: '$formattedMonth • ${_selectedShift == 'All' ? 'All Shifts' : _selectedShift}',
              totalStaff: totalTeachers,
              present: totalPresent,
              late: totalLate,
              absent: totalAbsent,
              rate: overallRate,
              staffLabel: 'Total Staff',
              presentLabel: 'Present Days',
              lateLabel: 'Late Days',
              absentLabel: 'Not recorded',
              rateLabel: 'checked in',
            ),
            const Gap(16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search teacher by name, employee ID, or class...',
                  hintStyle: typography.bodyMedium.copyWith(color: colors.textSecondary.withValues(alpha: 0.7)),
                  prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const Gap(12),

            // Shift & Rate Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Shifts ($totalTeachers)',
                    isSelected: _selectedShift == 'All',
                    color: colors.primary,
                    onTap: () => setState(() => _selectedShift = 'All'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Shift 1 ($shift1Count)',
                    isSelected: _selectedShift == 'Shift 1',
                    color: const Color(0xFF1D4ED8),
                    onTap: () => setState(() => _selectedShift = 'Shift 1'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Shift 2 ($shift2Count)',
                    isSelected: _selectedShift == 'Shift 2',
                    color: const Color(0xFF7C3AED),
                    onTap: () => setState(() => _selectedShift = 'Shift 2'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Dual Shift ($dualCount)',
                    isSelected: _selectedShift == 'Dual Shift',
                    color: const Color(0xFF4F46E5),
                    onTap: () => setState(() => _selectedShift = 'Dual Shift'),
                  ),
                  const Gap(12),
                  Container(width: 1, height: 24, color: colors.border),
                  const Gap(12),
                  _FilterChip(
                    label: 'High (>=85%)',
                    isSelected: _selectedRateFilter == 'High (>=85%)',
                    color: Colors.green,
                    onTap: () => setState(() => _selectedRateFilter = _selectedRateFilter == 'High (>=85%)' ? 'All' : 'High (>=85%)'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Avg (70-84%)',
                    isSelected: _selectedRateFilter == 'Avg (70-84%)',
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedRateFilter = _selectedRateFilter == 'Avg (70-84%)' ? 'All' : 'Avg (70-84%)'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Low (<70%)',
                    isSelected: _selectedRateFilter == 'Low (<70%)',
                    color: Colors.red,
                    onTap: () => setState(() => _selectedRateFilter = _selectedRateFilter == 'Low (<70%)' ? 'All' : 'Low (<70%)'),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Clarity note: Scheduled = the month's planned working days (uniform base)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.info, size: 16, color: Color(0xFF0284C7)),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _selectedShift == 'Shift 1' || _selectedShift == 'Shift 2'
                          ? '“Scheduled Days” = the madrasa’s planned working days for ${_selectedShift == 'Shift 1' ? 'Shift-1' : 'Shift-2'} this month — the same base for every teacher. '
                              'Present/Absent are counted against it; a teacher assigned to fewer of those days will show more absents. '
                              '“Not recorded” = a working day with no check-in, not a confirmed absence.'
                          : '“Scheduled Days” = the madrasa’s planned working days this month — the same base for every teacher — and Present/Absent are counted against it. '
                              'Pick a single shift for a clean per-shift total (recommended); “All Shifts” combines both shifts’ working days.',
                      style: typography.caption.copyWith(color: colors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            // Header for Teacher Roster list with Download Actions
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Rosters (${filtered.length})',
                      style: typography.bodyMediumSemiBold,
                    ),
                    Text(
                      'Tap any teacher to view day-by-day attendance history',
                      style: typography.caption.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.onDownload != null)
                  _ExportQuickButton(
                    label: 'Download',
                    icon: LucideIcons.download,
                    color: context.colors.primary,
                    tooltip: 'Download report (choose shift & format)',
                    onTap: () => widget.onDownload!(_selectedShift),
                  )
                else ...[
                  if (widget.onExportPdf != null) ...[
                    _ExportQuickButton(
                      label: 'PDF',
                      icon: LucideIcons.fileText,
                      color: Colors.red.shade700,
                      tooltip: 'Download PDF Report',
                      onTap: () => widget.onExportPdf!(_selectedShift),
                    ),
                    const Gap(6),
                  ],
                  if (widget.onExportExcel != null)
                    _ExportQuickButton(
                      label: 'Excel',
                      icon: LucideIcons.table,
                      color: Colors.green.shade800,
                      tooltip: 'Download Excel Sheet',
                      onTap: () => widget.onExportExcel!(_selectedShift),
                    ),
                ],
              ],
            ),
            const Gap(10),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No teachers match your search or shift filter.',
                    style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...filtered.map((row) => _TeacherReportRow(
                    row: row,
                    month: widget.month,
                    instituteId: widget.instituteId,
                    shift: _drillShift,
                  )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
    );
  }
}

// ── Header Segment Tab ────────────────────────────────────────────────────────

class _HeaderSegmentTab extends StatelessWidget {
  const _HeaderSegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? context.colors.primary : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

// ── Teacher Day-Wise Report Tab ───────────────────────────────────────────────

class _TeacherDayReportTab extends ConsumerStatefulWidget {
  const _TeacherDayReportTab({
    required this.date,
    required this.dateLabel,
    required this.instituteId,
    this.shift,
    this.refreshKey = 0,
    this.onExportPdf,
    this.onExportExcel,
    this.onDownload,
  });

  final String date;
  final String dateLabel;
  final String instituteId;
  final String? shift;
  final int refreshKey;
  final void Function([String? shift])? onExportPdf;
  final void Function([String? shift])? onExportExcel;
  final void Function([String? shift])? onDownload;

  @override
  ConsumerState<_TeacherDayReportTab> createState() => _TeacherDayReportTabState();
}

class _TeacherDayReportTabState extends ConsumerState<_TeacherDayReportTab> {
  String _selectedFilter = 'All';
  String _selectedShiftFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _syncShift(widget.shift);
  }

  @override
  void didUpdateWidget(covariant _TeacherDayReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shift != widget.shift) {
      _syncShift(widget.shift);
    }
  }

  void _syncShift(String? s) {
    if (s == 'Shift-1' || s == 'Shift 1') {
      _selectedShiftFilter = 'Shift 1';
    } else if (s == 'Shift-2' || s == 'Shift 2') {
      _selectedShiftFilter = 'Shift 2';
    } else if (s == 'Dual Shift') {
      _selectedShiftFilter = 'Dual Shift';
    } else {
      _selectedShiftFilter = 'All';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _matchesDayShift(Map<String, dynamic> t, String shiftFilter) {
    if (shiftFilter == 'All') return true;
    final shifts = (t['shifts'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final singleShift = t['shift']?.toString();
    final isDual = t['isDualShift'] == true || shifts.length > 1;
    if (shiftFilter == 'Dual Shift') return isDual;
    if (shiftFilter == 'Shift 1') {
      return shifts.contains('Shift-1') || shifts.contains('Shift 1') || singleShift == 'Shift-1' || singleShift == 'Shift 1';
    }
    if (shiftFilter == 'Shift 2') {
      return shifts.contains('Shift-2') || shifts.contains('Shift 2') || singleShift == 'Shift-2' || singleShift == 'Shift 2';
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final monthKey = widget.date.length >= 7 ? widget.date.substring(0, 7) : '';

    final params = _ReportParams(
      month: monthKey,
      date: widget.date,
      instituteId: widget.instituteId,
      type: 'teacher',
      shift: widget.shift,
      refreshKey: widget.refreshKey,
    );

    final reportAsync = ref.watch(_attendanceReportProvider(params));

    return reportAsync.when(
      data: (data) {
        final rawTeachers = (data['teachers'] as List?) ?? [];
        final teachers = rawTeachers.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        if (teachers.isEmpty) {
          return _EmptyReport(message: 'No teacher records found for ${widget.dateLabel}.');
        }

        // Overall counts
        int total = teachers.length;
        int s1Count = teachers.where((t) => _matchesDayShift(t, 'Shift 1')).length;
        int s2Count = teachers.where((t) => _matchesDayShift(t, 'Shift 2')).length;
        int dualCount = teachers.where((t) => _matchesDayShift(t, 'Dual Shift')).length;

        // Shift filtered pool
        final teachersInShift = teachers.where((t) => _matchesDayShift(t, _selectedShiftFilter)).toList();

        int present = 0, late = 0, absent = 0, onLeave = 0, notCheckedIn = 0, notScheduled = 0;
        for (final t in teachersInShift) {
          switch (_stateOf(t)) {
            case 'present':
              present++;
              break;
            case 'late':
              late++;
              break;
            case 'leave':
              onLeave++;
              break;
            case 'absent':
              absent++;
              break;
            case 'not_scheduled':
              notScheduled++;
              break;
            case 'not_checked_in':
            default:
              notCheckedIn++;
          }
        }

        final filtered = teachersInShift.where((t) {
          if (_selectedFilter != 'All' && _stateOf(t) != _selectedFilter) {
            return false;
          }

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final name = (t['fullName'] as String? ?? '').toLowerCase();
            final emp = (t['employeeId'] as String? ?? '').toLowerCase();
            final classes = (t['classes'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
            final subjects = (t['subjects'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
            final matchesClass = classes.any((c) => c.contains(q));
            final matchesSubject = subjects.any((s) => s.contains(q));
            if (!name.contains(q) && !emp.contains(q) && !matchesClass && !matchesSubject) {
              return false;
            }
          }

          return true;
        }).toList();

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _DayOverviewCard(
                dateLabel: widget.dateLabel,
                shiftContext: _selectedShiftFilter == 'All' ? 'All Shifts' : _selectedShiftFilter,
                totalStaff: teachersInShift.length,
                present: present,
                late: late,
                onLeave: onLeave,
                absent: absent,
                notCheckedIn: notCheckedIn,
                notScheduled: notScheduled,
              ),
            ),
            const Gap(12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search staff by name, ID, or assigned class...',
                    hintStyle: typography.bodyMedium.copyWith(color: colors.textSecondary.withValues(alpha: 0.7)),
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                ),
              ),
            ),
            const Gap(10),

            // Shift filter chips row
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All Shifts ($total)',
                    isSelected: _selectedShiftFilter == 'All',
                    color: colors.primary,
                    onTap: () => setState(() => _selectedShiftFilter = 'All'),
                  ),
                  const Gap(6),
                  _FilterChip(
                    label: 'Shift 1 ($s1Count)',
                    isSelected: _selectedShiftFilter == 'Shift 1',
                    color: const Color(0xFF1D4ED8),
                    onTap: () => setState(() => _selectedShiftFilter = 'Shift 1'),
                  ),
                  const Gap(6),
                  _FilterChip(
                    label: 'Shift 2 ($s2Count)',
                    isSelected: _selectedShiftFilter == 'Shift 2',
                    color: const Color(0xFF7C3AED),
                    onTap: () => setState(() => _selectedShiftFilter = 'Shift 2'),
                  ),
                  const Gap(6),
                  _FilterChip(
                    label: 'Dual Shift ($dualCount)',
                    isSelected: _selectedShiftFilter == 'Dual Shift',
                    color: const Color(0xFF4F46E5),
                    onTap: () => setState(() => _selectedShiftFilter = 'Dual Shift'),
                  ),
                ],
              ),
            ),
            const Gap(8),

            // Status filter chips (by honest attendance state).
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All (${teachersInShift.length})',
                    isSelected: _selectedFilter == 'All',
                    color: colors.primary,
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  const Gap(6),
                  _FilterChip(
                    label: 'Present ($present)',
                    isSelected: _selectedFilter == 'present',
                    color: _cPresent,
                    onTap: () => setState(() => _selectedFilter = 'present'),
                  ),
                  if (late > 0) ...[
                    const Gap(6),
                    _FilterChip(
                      label: 'Late ($late)',
                      isSelected: _selectedFilter == 'late',
                      color: _cLate,
                      onTap: () => setState(() => _selectedFilter = 'late'),
                    ),
                  ],
                  const Gap(6),
                  _FilterChip(
                    label: 'Not checked in ($notCheckedIn)',
                    isSelected: _selectedFilter == 'not_checked_in',
                    color: _cNotChecked,
                    onTap: () => setState(() => _selectedFilter = 'not_checked_in'),
                  ),
                  const Gap(6),
                  _FilterChip(
                    label: 'On Leave ($onLeave)',
                    isSelected: _selectedFilter == 'leave',
                    color: _cLeave,
                    onTap: () => setState(() => _selectedFilter = 'leave'),
                  ),
                  if (absent > 0) ...[
                    const Gap(6),
                    _FilterChip(
                      label: 'Absent ($absent)',
                      isSelected: _selectedFilter == 'absent',
                      color: _cAbsent,
                      onTap: () => setState(() => _selectedFilter = 'absent'),
                    ),
                  ],
                  const Gap(6),
                  _FilterChip(
                    label: 'Not scheduled ($notScheduled)',
                    isSelected: _selectedFilter == 'not_scheduled',
                    color: _cNotSched,
                    onTap: () => setState(() => _selectedFilter = 'not_scheduled'),
                  ),
                ],
              ),
            ),
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFilter == 'All' ? 'All Staff (${filtered.length})' : '${_stateVisual(_selectedFilter).label} (${filtered.length})',
                          style: typography.bodyMediumSemiBold,
                        ),
                        Text('Grouped by shift • Tap for logs & details',
                            style: typography.caption.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  if (widget.onDownload != null)
                    _ExportQuickButton(
                      label: 'Download',
                      icon: LucideIcons.download,
                      color: context.colors.primary,
                      tooltip: 'Download report (choose shift & format)',
                      onTap: () => widget.onDownload!(_selectedShiftFilter),
                    )
                  else ...[
                    if (widget.onExportPdf != null) ...[
                      _ExportQuickButton(
                        label: 'PDF',
                        icon: LucideIcons.fileText,
                        color: Colors.red.shade700,
                        tooltip: 'Download PDF Report',
                        onTap: () => widget.onExportPdf!(_selectedShiftFilter),
                      ),
                      const Gap(6),
                    ],
                    if (widget.onExportExcel != null)
                      _ExportQuickButton(
                        label: 'Excel',
                        icon: LucideIcons.table,
                        color: Colors.green.shade800,
                        tooltip: 'Download Excel Sheet',
                        onTap: () => widget.onExportExcel!(_selectedShiftFilter),
                      ),
                  ],
                ],
              ),
            ),
            const Gap(10),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                child: Center(
                  child: Text(
                    'No staff members match the selected filters.',
                    style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...filtered.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DayTeacherCard(
                      teacher: t,
                      dateLabel: widget.dateLabel,
                      onTap: () => _showTeacherDetailSheet(context, t, widget.dateLabel),
                      onRemind: () => _remindTeacher(context, t),
                    ),
                  )),
          ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
    );
  }

  void _showTeacherDetailSheet(BuildContext context, Map<String, dynamic> teacher, String dateLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TeacherDetailPopup(
        teacher: teacher,
        dateLabel: dateLabel,
      ),
    );
  }

  // Nudge a scheduled-but-not-checked-in teacher over WhatsApp (no API/cost —
  // opens a pre-filled chat the admin sends).
  Future<void> _remindTeacher(BuildContext context, Map<String, dynamic> teacher) async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = teacher['phone']?.toString() ?? '';
    final name = teacher['fullName']?.toString() ?? 'Ustad';
    if (phone.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No phone number on file for this teacher.')));
      return;
    }
    final msg = 'Assalamu alaikum $name,\n\nThis is a reminder to mark your attendance / check in for '
        '${widget.dateLabel}. Please check in as soon as you can.\n\nJazakAllah khair.';
    final ok = await WhatsAppService.send(phone, msg);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not open WhatsApp for this number.')));
    }
  }
}

// ── Attendance state → colour / label / icon ─────────────────────────────────
// A teacher's day resolves to one of these honest states. "Not checked in" is an
// operational gap (scheduled, no record yet) and is deliberately NOT the same as
// a confirmed "Absent"; "Not scheduled" means they had no class today.
const Color _cPresent = Color(0xFF16A34A);
const Color _cLate = Color(0xFFF97316);
const Color _cNotChecked = Color(0xFFD97706);
const Color _cLeave = Color(0xFF9333EA);
const Color _cAbsent = Color(0xFFDC2626);
const Color _cNotSched = Color(0xFF94A3B8);

typedef _StateVisual = ({String label, Color color, IconData icon});

_StateVisual _stateVisual(String state) {
  switch (state) {
    case 'present':
      return (label: 'Present', color: _cPresent, icon: LucideIcons.checkCircle2);
    case 'late':
      return (label: 'Late', color: _cLate, icon: LucideIcons.clock);
    case 'leave':
      return (label: 'On Leave', color: _cLeave, icon: LucideIcons.calendarOff);
    case 'absent':
      return (label: 'Absent', color: _cAbsent, icon: LucideIcons.xCircle);
    case 'not_scheduled':
      return (label: 'Not scheduled', color: _cNotSched, icon: LucideIcons.minusCircle);
    case 'not_checked_in':
    default:
      return (label: 'Not checked in', color: _cNotChecked, icon: LucideIcons.clock);
  }
}

// Resolve a teacher row to its state, falling back to the legacy status string
// for older payloads that predate `attendanceState`.
String _stateOf(Map<String, dynamic> t) {
  final s = t['attendanceState']?.toString();
  if (s != null && s.isNotEmpty) return s;
  switch (t['status']?.toString()) {
    case 'Present':
      return 'present';
    case 'Late':
      return 'late';
    case 'On Leave':
      return 'leave';
    default:
      return (t['isScheduled'] == true) ? 'not_checked_in' : 'not_scheduled';
  }
}

// A dependency-free donut (no chart package). Segments with value 0 are skipped.
class _AttendanceDonut extends StatelessWidget {
  const _AttendanceDonut({required this.segments, required this.child, this.size = 120});
  final List<({double value, Color color})> segments;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(segments, size * 0.15, context.colors.border),
        child: Center(child: child),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.thickness, this.trackColor);
  final List<({double value, Color color})> segments;
  final double thickness;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - thickness) / 2;
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = trackColor.withValues(alpha: 0.4);
    canvas.drawCircle(center, radius, track);
    if (total <= 0) return;

    const gap = 0.04; // radians of gap between slices
    double start = -math.pi / 2;
    final nonZero = segments.where((s) => s.value > 0).toList();
    for (final s in nonZero) {
      final sweep = (s.value / total) * (2 * math.pi) - (nonZero.length > 1 ? gap : 0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = s.color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep < 0 ? 0 : sweep, false, paint);
      start += (s.value / total) * (2 * math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.thickness != thickness || old.trackColor != trackColor;
}

// Honest daily overview: a check-in rate against who was actually scheduled,
// with "not checked in" and "not scheduled" split out from "absent".
class _DayOverviewCard extends StatelessWidget {
  const _DayOverviewCard({
    required this.dateLabel,
    this.shiftContext = 'All Shifts',
    required this.totalStaff,
    required this.present,
    required this.late,
    required this.onLeave,
    required this.absent,
    required this.notCheckedIn,
    required this.notScheduled,
  });

  final String dateLabel;
  final String shiftContext;
  final int totalStaff;
  final int present;
  final int late;
  final int onLeave;
  final int absent;
  final int notCheckedIn;
  final int notScheduled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final checkedIn = present + late;
    final scheduled = present + late + onLeave + absent + notCheckedIn;
    final rate = scheduled > 0 ? ((checkedIn / scheduled) * 100).round() : 0;

    final legend = <Widget>[
      _legendItem('Present', present, _cPresent),
      if (late > 0) _legendItem('Late', late, _cLate),
      _legendItem('Not checked in', notCheckedIn, _cNotChecked),
      _legendItem('On leave', onLeave, _cLeave),
      if (absent > 0) _legendItem('Absent', absent, _cAbsent),
      _legendItem('Not scheduled', notScheduled, _cNotSched, muted: true),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teacher daily attendance', style: typography.bodyMediumSemiBold),
                    Text('$dateLabel • $shiftContext',
                        style: typography.caption.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$totalStaff staff',
                    style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Gap(14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AttendanceDonut(
                size: 118,
                segments: [
                  (value: present.toDouble(), color: _cPresent),
                  (value: late.toDouble(), color: _cLate),
                  (value: notCheckedIn.toDouble(), color: _cNotChecked),
                  (value: onLeave.toDouble(), color: _cLeave),
                  (value: absent.toDouble(), color: _cAbsent),
                  (value: notScheduled.toDouble(), color: _cNotSched),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$rate%',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    Text('checked in', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                  ],
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('$scheduled scheduled today · ',
                            style: typography.caption.copyWith(color: colors.textSecondary)),
                        Text('$checkedIn checked in',
                            style: typography.caption.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Gap(10),
                    Wrap(spacing: 14, runSpacing: 8, children: legend),
                  ],
                ),
              ),
            ],
          ),
          if (notCheckedIn > 0) ...[
            const Gap(12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _cNotChecked.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cNotChecked.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.info, size: 14, color: _cNotChecked),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      '$notCheckedIn scheduled ${notCheckedIn == 1 ? 'teacher has' : 'teachers have'} no check-in yet — not the same as confirmed absent.',
                      style: typography.caption.copyWith(color: colors.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(String label, int value, Color color, {bool muted = false}) {
    return Builder(builder: (context) {
      final colors = context.colors;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: muted ? colors.textSecondary : colors.textPrimary,
            ),
          ),
          const Gap(5),
          Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? color : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DayTeacherCard extends StatelessWidget {
  const _DayTeacherCard({
    required this.teacher,
    required this.dateLabel,
    required this.onTap,
    this.onRemind,
  });

  final Map<String, dynamic> teacher;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final name = teacher['fullName'] as String? ?? 'Unknown';
    final employeeId = teacher['employeeId'] as String? ?? '';
    final state = _stateOf(teacher);
    final checkInAt = teacher['checkInAt'] as String?;
    final isScheduled = teacher['isScheduled'] as bool? ?? false;
    final leave = teacher['leaveDetails'] as Map<String, dynamic>?;
    final classes = (teacher['classes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final subjects = (teacher['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final hasPhone = (teacher['phone']?.toString().trim().isNotEmpty) ?? false;

    String? checkInFormatted;
    if (checkInAt != null) {
      try {
        final dt = DateTime.parse(checkInAt).toLocal();
        checkInFormatted = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final visual = _stateVisual(state);
    final Color statusColor = visual.color;
    final IconData statusIcon = visual.icon;
    final String statusLabel = visual.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: typography.bodyMediumSemiBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isScheduled) ...[
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Scheduled',
                                style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          if (teacher['isDualShift'] == true || ((teacher['shifts'] as List?)?.length ?? 0) > 1) ...[
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Dual Shift',
                                style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ] else if (teacher['shift'] != null && teacher['shift'].toString().isNotEmpty) ...[
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                teacher['shift'] == 'Shift-1' ? 'Shift 1' : (teacher['shift'] == 'Shift-2' ? 'Shift 2' : teacher['shift'].toString()),
                                style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(2),
                      Text(
                        employeeId,
                        style: typography.caption.copyWith(color: colors.textSecondary),
                      ),
                      if (classes.isNotEmpty || subjects.isNotEmpty) ...[
                        const Gap(4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (classes.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.school, size: 10, color: colors.primary),
                                    const Gap(3),
                                    Text(
                                      classes.join(', '),
                                      style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            if (subjects.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.bookOpen, size: 10, color: Color(0xFF0284C7)),
                                    const Gap(3),
                                    Text(
                                      subjects.join(', '),
                                      style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      const Gap(4),
                      if (state == 'leave' && leave != null)
                        Text(
                          'Leave: ${leave['leaveType'] ?? 'Leave'}',
                          style: const TextStyle(color: _cLeave, fontSize: 11, fontWeight: FontWeight.w500),
                        )
                      else if (checkInFormatted != null)
                        Row(
                          children: [
                            Icon(LucideIcons.clock, size: 12, color: colors.textSecondary),
                            const Gap(4),
                            Text(
                              'In at $checkInFormatted${teacher['verificationMethod'] != null && teacher['verificationMethod'].toString().isNotEmpty ? ' · ${teacher['verificationMethod']}' : ''}',
                              style: typography.caption.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        )
                      else
                        Text(
                          state == 'not_scheduled' ? 'No class scheduled today' : 'No check-in record',
                          style: typography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                ),
                const Gap(8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const Gap(4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state == 'not_checked_in' && onRemind != null && hasPhone) ...[
                      const Gap(6),
                      GestureDetector(
                        onTap: onRemind,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cNotChecked.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _cNotChecked.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.messageCircle, size: 11, color: _cNotChecked),
                              Gap(4),
                              Text('Remind',
                                  style: TextStyle(color: _cNotChecked, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const Gap(6),
                      Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary.withValues(alpha: 0.5)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherDetailPopup extends StatelessWidget {
  const _TeacherDetailPopup({
    required this.teacher,
    required this.dateLabel,
  });

  final Map<String, dynamic> teacher;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final name = teacher['fullName'] as String? ?? 'Teacher';
    final employeeId = teacher['employeeId'] as String? ?? '';
    final phone = teacher['phone'] as String?;
    final state = _stateOf(teacher);
    final isScheduled = teacher['isScheduled'] as bool? ?? false;
    final checkInAt = teacher['checkInAt'] as String?;
    final verificationMethod = teacher['verificationMethod'] as String? ?? 'Not Specified';
    final remarks = teacher['remarks'] as String?;
    final leave = teacher['leaveDetails'] as Map<String, dynamic>?;

    String? fullCheckInFormatted;
    if (checkInAt != null) {
      try {
        final dt = DateTime.parse(checkInAt).toLocal();
        fullCheckInFormatted = DateFormat('hh:mm:ss a').format(dt);
      } catch (_) {
        fullCheckInFormatted = checkInAt;
      }
    }

    final visual = _stateVisual(state);
    final Color statusColor = visual.color;
    final IconData statusIcon = visual.icon;
    final String status = visual.label;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'T',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: typography.h4),
                          const Gap(2),
                          Text('ID: $employeeId', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                          if (phone != null && phone.isNotEmpty) ...[
                            const Gap(2),
                            Text('Tel: $phone', style: typography.caption.copyWith(color: colors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const Gap(6),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Text('Attendance Log & Details', style: typography.bodyMediumSemiBold),
              const Gap(8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    _logRow(context, 'Date', dateLabel, LucideIcons.calendar),
                    const Divider(height: 20),
                    _logRow(
                      context,
                      'Check-in Time',
                      fullCheckInFormatted ?? 'No check-in record',
                      LucideIcons.clock,
                      highlight: fullCheckInFormatted != null,
                    ),
                    const Divider(height: 20),
                    _logRow(
                      context,
                      'Verification Method',
                      verificationMethod,
                      LucideIcons.shieldCheck,
                    ),
                    const Divider(height: 20),
                    _logRow(
                      context,
                      'Teaching Schedule',
                      isScheduled ? 'Scheduled for classes' : 'No classes scheduled',
                      LucideIcons.calendarClock,
                    ),
                    if ((teacher['classes'] as List?)?.isNotEmpty == true) ...[
                      const Divider(height: 20),
                      _logRow(
                        context,
                        'Assigned Classes',
                        (teacher['classes'] as List).join(', '),
                        LucideIcons.school,
                      ),
                    ],
                    if ((teacher['subjects'] as List?)?.isNotEmpty == true) ...[
                      const Divider(height: 20),
                      _logRow(
                        context,
                        'Assigned Subjects',
                        (teacher['subjects'] as List).join(', '),
                        LucideIcons.bookOpen,
                      ),
                    ],
                    if (remarks != null && remarks.isNotEmpty) ...[
                      const Divider(height: 20),
                      _logRow(context, 'Remarks', remarks, LucideIcons.messageSquare),
                    ],
                  ],
                ),
              ),
              if (leave != null) ...[
                const Gap(16),
                Text('Leave Information', style: typography.bodyMediumSemiBold),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _logRow(context, 'Leave Type', leave['leaveType']?.toString() ?? 'Leave', LucideIcons.calendarX),
                      const Divider(height: 20),
                      _logRow(context, 'Leave Status', leave['status']?.toString() ?? 'Approved', LucideIcons.check),
                      if (leave['reason'] != null && leave['reason'].toString().isNotEmpty) ...[
                        const Divider(height: 20),
                        _logRow(context, 'Reason', leave['reason'].toString(), LucideIcons.info),
                      ],
                    ],
                  ),
                ),
              ],
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _logRow(BuildContext context, String label, String value, IconData icon, {bool highlight = false}) {
    final colors = context.colors;
    final typography = context.typography;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const Gap(10),
        Text(label, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: highlight
                ? typography.bodyMediumSemiBold.copyWith(color: colors.primary)
                : typography.bodyMediumSemiBold,
          ),
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _TeacherReportRow extends StatelessWidget {
  const _TeacherReportRow({required this.row, required this.month, required this.instituteId, this.shift});
  final Map<String, dynamic> row;
  final String month;
  final String instituteId;
  final String? shift;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final name = row['fullName'] as String? ?? 'Unknown';
    final employeeId = row['employeeId'] as String? ?? '';
    final teacherId = row['teacherId'] as String? ?? '';
    final present = row['present'] as int? ?? 0;
    final absent = row['absent'] as int? ?? 0;
    final late = row['late'] as int? ?? 0;
    final leave = (row['leave'] as num?)?.toInt() ?? 0;
    final scheduledDays = (row['scheduledDays'] as num?)?.toInt() ?? (row['total'] as int? ?? 0);
    final total = row['total'] as int? ?? scheduledDays;
    final rate = row['rate'] as int? ?? 0;
    final classes = (row['classes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final subjects = (row['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return InkWell(
      onTap: teacherId.isEmpty
          ? null
          : () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: colors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => _TeacherDaysSheet(
                  teacherId: teacherId,
                  teacherName: name,
                  month: month,
                  instituteId: instituteId,
                  shift: shift,
                ),
              ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, style: typography.bodyMediumSemiBold)),
                    if (row['isDualShift'] == true || ((row['shifts'] as List?)?.length ?? 0) > 1) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Dual Shift',
                          style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ] else if ((row['shifts'] as List?)?.isNotEmpty == true) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (row['shifts'] as List).first == 'Shift-1' ? 'Shift 1' : 'Shift 2',
                          style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(2),
                Text(employeeId, style: typography.caption.copyWith(color: colors.textSecondary)),
                if (classes.isNotEmpty || subjects.isNotEmpty) ...[
                  const Gap(4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (classes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.school, size: 10, color: colors.primary),
                              const Gap(3),
                              Text(
                                classes.join(', '),
                                style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      if (subjects.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.bookOpen, size: 10, color: Color(0xFF0284C7)),
                              const Gap(3),
                              Text(
                                subjects.join(', '),
                                style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                const Gap(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (scheduledDays > 0) _StatChip(label: 'Scheduled', value: scheduledDays, color: const Color(0xFF0284C7)),
                    _StatChip(label: 'Present', value: present, color: Colors.green),
                    if (late > 0) _StatChip(label: 'Late', value: late, color: Colors.orange),
                    if (leave > 0) _StatChip(label: 'Leave', value: leave, color: Colors.purple),
                    _StatChip(label: 'Absent', value: absent, color: Colors.red),
                    _StatChip(label: 'Total', value: total, color: const Color(0xFF4B5563)),
                  ],
                ),
                if (row['shiftBreakdown'] != null && row['shiftBreakdown'] is Map) ...[
                  () {
                    final sb = row['shiftBreakdown'] as Map<String, dynamic>;
                    if (sb.isEmpty) return const SizedBox.shrink();
                    // Only show a shift's chip when it has activity in this view, and
                    // when a single shift is selected show only that shift's chip —
                    // so a Shift-1 report never prints an empty "Shift 2: 0/0".
                    final chips = sb.entries.where((entry) {
                      final sKey = entry.key;
                      if (shift != null && shift!.isNotEmpty && shift != 'All' && sKey != shift) {
                        return false;
                      }
                      final sData = entry.value as Map<String, dynamic>;
                      final p = (sData['present'] as num?)?.toInt() ?? 0;
                      final t = (sData['total'] as num?)?.toInt() ?? 0;
                      final l = (sData['late'] as num?)?.toInt() ?? 0;
                      final a = (sData['absent'] as num?)?.toInt() ?? 0;
                      return (p + t + l + a) > 0;
                    }).toList();
                    if (chips.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: chips.map((entry) {
                          final sKey = entry.key;
                          final sData = entry.value as Map<String, dynamic>;
                          final sLabel = sKey == 'Shift-1' ? 'Shift 1' : (sKey == 'Shift-2' ? 'Shift 2' : sKey);
                          final sColor = sKey == 'Shift-1' ? const Color(0xFF1D4ED8) : const Color(0xFF6D28D9);
                          final sPresent = (sData['present'] as num?)?.toInt() ?? 0;
                          final sTotal = (sData['total'] as num?)?.toInt() ?? 0;
                          // Backend omits a per-shift rate — derive it from present/total.
                          final sRate = sTotal > 0 ? ((sPresent / sTotal) * 100).round() : 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: sColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '$sLabel: Present $sPresent/$sTotal ($sRate%)',
                              style: TextStyle(color: sColor, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }(),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _rateColor(rate).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$rate% Rate',
              style: TextStyle(color: _rateColor(rate), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 85) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }
}

// Drill-down: one teacher's day-by-day attendance for the selected month.
class _TeacherDaysSheet extends ConsumerWidget {
  const _TeacherDaysSheet({
    required this.teacherId,
    required this.teacherName,
    required this.month,
    required this.instituteId,
    this.shift,
  });
  final String teacherId;
  final String teacherName;
  final String month;
  final String instituteId;
  final String? shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final async = ref.watch(_teacherDaysProvider(
      _TeacherDaysParams(teacherId: teacherId, month: month, instituteId: instituteId, shift: shift),
    ));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          const Gap(10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
          const Gap(12),
          Text(teacherName, style: typography.h4),
          Text(
            (shift != null && shift!.isNotEmpty && shift != 'All')
                ? 'Attendance — $month • $shift only'
                : 'Attendance — $month',
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const Gap(12),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
              data: (days) {
                if (days.isEmpty) {
                  return Center(child: Text('No attendance recorded for $month.',
                      style: typography.bodyMedium.copyWith(color: colors.textSecondary)));
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: days.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
                  itemBuilder: (_, i) {
                    final d = days[i];
                    final date = DateTime.tryParse(d['date']?.toString() ?? '');
                    final status = d['status']?.toString() ?? '';
                    final shift = d['shift']?.toString();
                    final label = date != null ? DateFormat('EEE, dd MMM yyyy').format(date) : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: typography.bodyMedium),
                              if (shift != null && shift.isNotEmpty) ...[
                                const Gap(2),
                                Text(
                                  shift == 'Shift-1' ? 'Shift 1' : (shift == 'Shift-2' ? 'Shift 2' : shift),
                                  style: typography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _dayStatusChip(status),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayStatusChip(String status) {
    Color c;
    switch (status) {
      case 'Present': c = Colors.green; break;
      case 'Late': c = Colors.orange; break;
      case 'Absent': c = Colors.red; break;
      default: c = Colors.grey;
    }
    final t = status.isEmpty ? '—' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clipboardX, size: 56, color: colors.textSecondary.withValues(alpha: 0.3)),
          const Gap(16),
          Text(message, style: context.typography.bodyLarge.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
