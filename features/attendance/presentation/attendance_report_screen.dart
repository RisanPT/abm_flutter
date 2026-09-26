import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
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
    this.refreshKey = 0,
  });
  final String month;
  final String? date;
  final String instituteId;
  final String type;
  final int refreshKey;   // increment to force re-fetch same month/date

  @override
  bool operator ==(Object other) =>
      other is _ReportParams &&
      month == other.month &&
      date == other.date &&
      instituteId == other.instituteId &&
      type == other.type &&
      refreshKey == other.refreshKey;

  @override
  int get hashCode => Object.hash(month, date, instituteId, type, refreshKey);
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
    final response = await dio.get(endpoint, queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  },
);

// Per-teacher day-by-day rows for the drill-down.
class _TeacherDaysParams {
  const _TeacherDaysParams({required this.teacherId, required this.month, required this.instituteId});
  final String teacherId;
  final String month;
  final String instituteId;
  @override
  bool operator ==(Object other) =>
      other is _TeacherDaysParams &&
      teacherId == other.teacherId &&
      month == other.month &&
      instituteId == other.instituteId;
  @override
  int get hashCode => Object.hash(teacherId, month, instituteId);
}

final _teacherDaysProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, _TeacherDaysParams>(
  (ref, p) async {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/attendance/teacher-report/${p.teacherId}', queryParameters: {
      'month': p.month,
      'instituteId': p.instituteId,
    });
    final days = ((res.data as Map)['days'] as List?) ?? [];
    return days.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  Future<void> _exportAttendancePdf() async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    try {
      final institute = ref.read(selectedInstituteProvider);
      final isStudentTab = _reportType == 'student';
      final type = isStudentTab ? 'student' : 'teacher';
      final isDayWise = _viewMode == 'day';
      final params = _ReportParams(
        month: _monthKey,
        date: isDayWise ? _dayKey : null,
        instituteId: institute.id,
        type: type,
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
          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (context) => [
                pw.Text(
                  'Teacher Daily Attendance Report',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Date: $_dayLabel'),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: ['Emp ID', 'Teacher Name', 'Status', 'Check-in Time', 'Method', 'Remarks / Leave'],
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
                    return [
                      r['employeeId']?.toString() ?? '',
                      r['fullName']?.toString() ?? '',
                      r['status']?.toString() ?? '',
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
          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (context) => [
                pw.Text(
                  'Student Daily Attendance Report',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Date: $_dayLabel'),
                pw.SizedBox(height: 16),
                ...summary.expand((cRow) {
                  final c = cRow as Map<String, dynamic>;
                  final cName = c['classroom']?.toString() ?? 'Unknown';
                  final students = (c['students'] as List?) ?? [];
                  if (students.isEmpty) return <pw.Widget>[];
                  return [
                    pw.SizedBox(height: 14),
                    pw.Text('Classroom: $cName (Present: ${c['present'] ?? 0}, Absent: ${c['absent'] ?? 0}, Rate: ${c['rate'] ?? 0}%)',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.TableHelper.fromTextArray(
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

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              isStudentTab
                  ? 'Student Monthly Attendance Report'
                  : 'Teacher Monthly Attendance Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Date: ${DateFormat('MMMM yyyy').format(_selectedDate)}'),
            pw.SizedBox(height: 16),
            if (isStudentTab)
              if (studentSummary.isNotEmpty)
                ...() {
                  final Map<String, List<Map<String, dynamic>>> byClass = {};
                  for (final s in studentSummary) {
                    final c = (s as Map<String, dynamic>)['classroom']?.toString() ?? 'Unknown';
                    byClass.putIfAbsent(c, () => []).add(s);
                  }

                  final List<pw.Widget> widgets = [];
                  for (final c in byClass.keys.toList()..sort()) {
                    widgets.add(pw.SizedBox(height: 16));
                    widgets.add(
                      pw.Text('Classroom: $c', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))
                    );
                    widgets.add(pw.SizedBox(height: 8));

                    final students = byClass[c]!..sort((a, b) =>
                      (a['fullName']?.toString() ?? '').compareTo(b['fullName']?.toString() ?? ''));

                    widgets.add(
                      pw.TableHelper.fromTextArray(
                        headers: ['Admn No', 'Student Name', 'Present Days', 'Absent Days', 'Late Days', 'Total Days', 'Rate'],
                        data: students.map((r) {
                          return [
                            r['admissionNumber']?.toString() ?? '',
                            r['fullName']?.toString() ?? '',
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
                  headers: ['Classroom', 'Present Days', 'Absent Days', 'Late Days', 'Total Days', 'Attendance Rate'],
                  data: summary.map((row) {
                    final r = row as Map<String, dynamic>;
                    return [
                      r['classroom']?.toString() ?? '',
                      r['present']?.toString() ?? '0',
                      r['absent']?.toString() ?? '0',
                      r['late']?.toString() ?? '0',
                      r['total']?.toString() ?? '0',
                      '${r['rate'] ?? 0}%',
                    ];
                  }).toList(),
                )
            else
              pw.TableHelper.fromTextArray(
                headers: ['Employee ID', 'Full Name', 'Present Days', 'Absent Days', 'Late Days', 'Total Days', 'Attendance Rate'],
                data: summary.map((row) {
                  final r = row as Map<String, dynamic>;
                  return [
                    r['employeeId']?.toString() ?? '',
                    r['fullName']?.toString() ?? '',
                    r['present']?.toString() ?? '0',
                    r['absent']?.toString() ?? '0',
                    r['late']?.toString() ?? '0',
                    r['total']?.toString() ?? '0',
                    '${r['rate'] ?? 0}%',
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

  Future<void> _exportAttendanceExcel() async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    try {
      final institute = ref.read(selectedInstituteProvider);
      final isStudentTab = _reportType == 'student';
      final type = isStudentTab ? 'student' : 'teacher';
      final isDayWise = _viewMode == 'day';
      final params = _ReportParams(
        month: _monthKey,
        date: isDayWise ? _dayKey : null,
        instituteId: institute.id,
        type: type,
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
      final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];

      if (isDayWise) {
        if (!isStudentTab) {
          // Teacher daily excel
          final rows = (data['teachers'] as List?) ?? [];
          sheet.appendRow(['Employee ID', 'Name', 'Status', 'Check-in Time', 'Method', 'Remarks']
              .map((e) => TextCellValue(e)).toList());
          for (final r0 in rows) {
            final r = r0 as Map<String, dynamic>;
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
            sheet.appendRow([
              TextCellValue(r['employeeId']?.toString() ?? ''),
              TextCellValue(r['fullName']?.toString() ?? ''),
              TextCellValue(r['status']?.toString() ?? ''),
              TextCellValue(checkIn),
              TextCellValue(r['verificationMethod']?.toString() ?? '—'),
              TextCellValue((r['remarks']?.toString().isNotEmpty == true) ? r['remarks'] : (leaveInfo.isNotEmpty ? leaveInfo : '—')),
            ]);
          }
        } else {
          // Student daily excel
          final summary = (data['summary'] as List?) ?? [];
          sheet.appendRow(['Classroom', 'Admission No', 'Student Name', 'Status', 'Remarks', 'Parent Contact']
              .map((e) => TextCellValue(e)).toList());
          for (final cRow in summary) {
            final c = cRow as Map<String, dynamic>;
            final cName = c['classroom']?.toString() ?? '';
            final students = (c['students'] as List?) ?? [];
            for (final sRow in students) {
              final s = sRow as Map<String, dynamic>;
              sheet.appendRow([
                TextCellValue(cName),
                TextCellValue(s['admissionNumber']?.toString() ?? ''),
                TextCellValue(s['fullName']?.toString() ?? ''),
                TextCellValue(s['status']?.toString() ?? ''),
                TextCellValue(s['remarks']?.toString() ?? ''),
                TextCellValue(s['parentContact']?.toString() ?? ''),
              ]);
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
        final rows = (data['studentSummary'] as List?) ?? [];
        sheet.appendRow(['Admission No', 'Name', 'Classroom', 'Present', 'Absent', 'Late', 'Total', 'Rate %']
            .map((e) => TextCellValue(e)).toList());
        for (final r0 in rows) {
          final r = r0 as Map<String, dynamic>;
          sheet.appendRow([
            TextCellValue(r['admissionNumber']?.toString() ?? ''),
            TextCellValue(r['fullName']?.toString() ?? ''),
            TextCellValue(r['classroom']?.toString() ?? ''),
            IntCellValue((r['present'] as num?)?.toInt() ?? 0),
            IntCellValue((r['absent'] as num?)?.toInt() ?? 0),
            IntCellValue((r['late'] as num?)?.toInt() ?? 0),
            IntCellValue((r['total'] as num?)?.toInt() ?? 0),
            IntCellValue((r['rate'] as num?)?.toInt() ?? 0),
          ]);
        }
      } else {
        final rows = (data['summary'] as List?) ?? [];
        sheet.appendRow(['Employee ID', 'Name', 'Present', 'Absent', 'Late', 'Total', 'Rate %']
            .map((e) => TextCellValue(e)).toList());
        for (final r0 in rows) {
          final r = r0 as Map<String, dynamic>;
          sheet.appendRow([
            TextCellValue(r['employeeId']?.toString() ?? ''),
            TextCellValue(r['fullName']?.toString() ?? ''),
            IntCellValue((r['present'] as num?)?.toInt() ?? 0),
            IntCellValue((r['absent'] as num?)?.toInt() ?? 0),
            IntCellValue((r['late'] as num?)?.toInt() ?? 0),
            IntCellValue((r['total'] as num?)?.toInt() ?? 0),
            IntCellValue((r['rate'] as num?)?.toInt() ?? 0),
          ]);
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

  void _showDownloadOptions(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isStudent = _reportType == 'student';
    final isDayWise = _viewMode == 'day';
    final periodText = isDayWise ? _dayLabel : _monthLabel;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
                        Text('Download Attendance Report', style: typography.h4),
                        Text(
                          '${isStudent ? 'Student' : 'Teacher'} attendance for $periodText',
                          style: typography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportAttendancePdf();
                  },
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
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.fileText, color: Colors.red, size: 22),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export PDF Document', style: typography.bodyMediumSemiBold),
                              const Gap(2),
                              Text('Share or print official formatted report with summary & tables',
                                  style: typography.caption.copyWith(color: colors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportAttendanceExcel();
                  },
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
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.table, color: Colors.green, size: 22),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export Excel Spreadsheet (.xlsx)', style: typography.bodyMediumSemiBold),
                              const Gap(2),
                              Text('Download .xlsx file with full breakdown and calculations',
                                  style: typography.caption.copyWith(color: colors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
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
                // Category Switcher: Students vs Teachers
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeaderSegmentTab(
                        label: 'Students',
                        isSelected: _reportType == 'student',
                        onTap: () => setState(() {
                          _reportType = 'student';
                          _refreshKey++;
                        }),
                      ),
                      _HeaderSegmentTab(
                        label: 'Teachers',
                        isSelected: _reportType == 'teacher',
                        onTap: () => setState(() {
                          _reportType = 'teacher';
                          _refreshKey++;
                        }),
                      ),
                    ],
                  ),
                ),
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
                    refreshKey: _refreshKey,
                    onExportPdf: _exportAttendancePdf,
                    onExportExcel: _exportAttendanceExcel,
                  )
                : (_viewMode == 'day'
                    ? _TeacherDayReportTab(
                        date: _dayKey,
                        dateLabel: _dayLabel,
                        instituteId: institute.id,
                        refreshKey: _refreshKey,
                        onExportPdf: _exportAttendancePdf,
                        onExportExcel: _exportAttendanceExcel,
                      )
                    : _TeacherReportTab(
                        month: _monthKey,
                        instituteId: institute.id,
                        refreshKey: _refreshKey,
                        onExportPdf: _exportAttendancePdf,
                        onExportExcel: _exportAttendanceExcel,
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
    this.refreshKey = 0,
    this.onExportPdf,
    this.onExportExcel,
  });

  final String month;
  final String date;
  final String dateLabel;
  final bool isDayWise;
  final String instituteId;
  final int refreshKey;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;

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
                if (widget.onExportExcel != null) ...[
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
    required this.allStudentSummaries,
  });

  final Map<String, dynamic> classroomData;
  final bool isDayWise;
  final String periodLabel;
  final List<Map<String, dynamic>> allStudentSummaries;

  @override
  State<_ClassroomStudentsSheet> createState() => _ClassroomStudentsSheetState();
}

class _ClassroomStudentsSheetState extends State<_ClassroomStudentsSheet> {
  final TextEditingController _studentSearchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _studentSearchCtrl.dispose();
    super.dispose();
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

    List<Map<String, dynamic>> students = [];
    if (widget.isDayWise) {
      final raw = (widget.classroomData['students'] as List?) ?? [];
      students = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      students = widget.allStudentSummaries
          .where((s) => (s['classroom']?.toString() ?? '') == className)
          .toList();
    }

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
        } else {
          final sAbsent = (s['absent'] as int?) ?? 0;
          if (_statusFilter == 'Absent' && sAbsent == 0) return false;
        }
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
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
                        Text(widget.periodLabel, style: typography.caption.copyWith(color: colors.textSecondary)),
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
            const Gap(14),

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
                    _sheetMetric('Total', students.length.toString(), colors.textPrimary),
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
            if (widget.isDayWise)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _chip('All (${students.length})', 'All', colors.primary),
                    const Gap(6),
                    _chip('Present ($present)', 'Present', Colors.green),
                    const Gap(6),
                    if (late > 0) ...[
                      _chip('Late ($late)', 'Late', Colors.orange),
                      const Gap(6),
                    ],
                    _chip('Absent ($absent)', 'Absent', Colors.red),
                  ],
                ),
              ),
            const Gap(12),

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
                        final remarks = s['remarks'] as String?;

                        if (widget.isDayWise) {
                          final status = s['status'] as String? ?? 'Absent';
                          final Color statusColor = status == 'Present'
                              ? Colors.green
                              : (status == 'Late' ? Colors.orange : Colors.red);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                      Text(name, style: typography.bodyMediumSemiBold),
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
                              ],
                            ),
                          );
                        } else {
                          // Monthly view item
                          final sPresent = (s['present'] as int?) ?? 0;
                          final sAbsent = (s['absent'] as int?) ?? 0;
                          final sTotal = (s['total'] as int?) ?? 0;
                          final sRate = (s['rate'] as int?) ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                      Text(name, style: typography.bodyMediumSemiBold),
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
                              ],
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
    if (widget.isDayWise) {
      final raw = (widget.classroomData['students'] as List?) ?? [];
      rawList = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
          pw.Text('Present: $present | Absent: $absent | Late: $late | Attendance Rate: $rate%',
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

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
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

// ── Teacher Report Tab ────────────────────────────────────────────────────────

class _TeacherReportTab extends ConsumerWidget {
  const _TeacherReportTab({
    required this.month,
    required this.instituteId,
    this.refreshKey = 0,
    this.onExportPdf,
    this.onExportExcel,
  });
  final String month;
  final String instituteId;
  final int refreshKey;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = _ReportParams(month: month, instituteId: instituteId, type: 'teacher', refreshKey: refreshKey);
    final reportAsync = ref.watch(_attendanceReportProvider(params));
    return reportAsync.when(
      data: (data) {
        final rawSummary = (data['summary'] as List?) ?? [];
        final summary = rawSummary.where((row) {
          final r = row as Map<String, dynamic>;
          final name = r['fullName'] as String?;
          return name != null && name.isNotEmpty && name.toLowerCase() != 'unknown';
        }).toList();

        if (summary.isEmpty) {
          return _EmptyReport(message: 'No teacher attendance recorded for $month.');
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teacher Attendance — $month', style: context.typography.h4),
                      const Gap(2),
                      Text('Tap a teacher to see day-by-day attendance.',
                          style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                if (onExportPdf != null) ...[
                  _ExportQuickButton(
                    label: 'PDF',
                    icon: LucideIcons.fileText,
                    color: Colors.red.shade700,
                    tooltip: 'Download PDF Report',
                    onTap: onExportPdf!,
                  ),
                  const Gap(6),
                ],
                if (onExportExcel != null) ...[
                  _ExportQuickButton(
                    label: 'Excel',
                    icon: LucideIcons.table,
                    color: Colors.green.shade800,
                    tooltip: 'Download Excel Sheet',
                    onTap: onExportExcel!,
                  ),
                ],
              ],
            ),
            const Gap(12),
            ...summary.map((row) => _TeacherReportRow(
                  row: row as Map<String, dynamic>,
                  month: month,
                  instituteId: instituteId,
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
    this.refreshKey = 0,
    this.onExportPdf,
    this.onExportExcel,
  });

  final String date;
  final String dateLabel;
  final String instituteId;
  final int refreshKey;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;

  @override
  ConsumerState<_TeacherDayReportTab> createState() => _TeacherDayReportTabState();
}

class _TeacherDayReportTabState extends ConsumerState<_TeacherDayReportTab> {
  String _selectedFilter = 'All';

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
      refreshKey: widget.refreshKey,
    );

    final reportAsync = ref.watch(_attendanceReportProvider(params));

    return reportAsync.when(
      data: (data) {
        final counts = (data['counts'] as Map<String, dynamic>?) ?? {};
        final int total = counts['total'] as int? ?? 0;
        final int present = counts['present'] as int? ?? 0;
        final int late = counts['late'] as int? ?? 0;
        final int absent = counts['absent'] as int? ?? 0;
        final int onLeave = counts['onLeave'] as int? ?? 0;

        final rawTeachers = (data['teachers'] as List?) ?? [];
        final teachers = rawTeachers.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        if (teachers.isEmpty) {
          return _EmptyReport(message: 'No teacher records found for ${widget.dateLabel}.');
        }

        final filtered = teachers.where((t) {
          if (_selectedFilter == 'All') return true;
          return (t['status']?.toString() ?? '') == _selectedFilter;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Daily Summary Metrics Card
            _DaySummaryCard(
              dateLabel: widget.dateLabel,
              total: total,
              present: present,
              late: late,
              absent: absent,
              onLeave: onLeave,
            ),
            const Gap(16),
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All ($total)',
                    isSelected: _selectedFilter == 'All',
                    color: colors.primary,
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Present ($present)',
                    isSelected: _selectedFilter == 'Present',
                    color: Colors.green,
                    onTap: () => setState(() => _selectedFilter = 'Present'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Late ($late)',
                    isSelected: _selectedFilter == 'Late',
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedFilter = 'Late'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Absent ($absent)',
                    isSelected: _selectedFilter == 'Absent',
                    color: Colors.red,
                    onTap: () => setState(() => _selectedFilter = 'Absent'),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'On Leave ($onLeave)',
                    isSelected: _selectedFilter == 'On Leave',
                    color: Colors.purple,
                    onTap: () => setState(() => _selectedFilter = 'On Leave'),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFilter == 'All' ? 'All Staff (${filtered.length})' : '$_selectedFilter (${filtered.length})',
                      style: typography.bodyMediumSemiBold,
                    ),
                    Text(
                      'Tap for logs & details',
                      style: typography.caption.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
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
                if (widget.onExportExcel != null) ...[
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
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No staff members with status "$_selectedFilter"',
                    style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...filtered.map((t) => _DayTeacherCard(
                    teacher: t,
                    dateLabel: widget.dateLabel,
                    onTap: () => _showTeacherDetailSheet(context, t, widget.dateLabel),
                  )),
          ],
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
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.dateLabel,
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
    required this.onLeave,
  });

  final String dateLabel;
  final int total;
  final int present;
  final int late;
  final int absent;
  final int onLeave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF0F4A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.calendarCheck, color: Colors.white, size: 24),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff Daily Attendance', style: typography.bodySmall.copyWith(color: Colors.white70)),
                    Text(dateLabel, style: typography.bodyLargeSemiBold.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$total Staff', style: typography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Gap(18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric('Present', present, Colors.greenAccent),
              _metric('Late', late, Colors.amberAccent),
              _metric('Absent', absent, const Color(0xFFFF8A80)),
              _metric('On Leave', onLeave, const Color(0xFFCE93D8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
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
  });

  final Map<String, dynamic> teacher;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final name = teacher['fullName'] as String? ?? 'Unknown';
    final employeeId = teacher['employeeId'] as String? ?? '';
    final status = teacher['status'] as String? ?? 'Absent';
    final checkInAt = teacher['checkInAt'] as String?;
    final isScheduled = teacher['isScheduled'] as bool? ?? false;
    final leave = teacher['leaveDetails'] as Map<String, dynamic>?;

    String? checkInFormatted;
    if (checkInAt != null) {
      try {
        final dt = DateTime.parse(checkInAt).toLocal();
        checkInFormatted = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final Color statusColor;
    final IconData statusIcon;
    switch (status) {
      case 'Present':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle2;
        break;
      case 'Late':
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
        break;
      case 'On Leave':
        statusColor = Colors.purple;
        statusIcon = LucideIcons.calendarOff;
        break;
      case 'Absent':
      default:
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
        break;
    }

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
                        ],
                      ),
                      const Gap(2),
                      Text(
                        employeeId,
                        style: typography.caption.copyWith(color: colors.textSecondary),
                      ),
                      const Gap(4),
                      if (status == 'On Leave' && leave != null)
                        Text(
                          'Leave: ${leave['leaveType'] ?? 'Leave'}',
                          style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w500),
                        )
                      else if (checkInFormatted != null)
                        Row(
                          children: [
                            Icon(LucideIcons.clock, size: 12, color: colors.textSecondary),
                            const Gap(4),
                            Text(
                              'In at $checkInFormatted',
                              style: typography.caption.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        )
                      else
                        Text(
                          'No check-in record',
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
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(6),
                    Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary.withValues(alpha: 0.5)),
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
    final status = teacher['status'] as String? ?? 'Absent';
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

    final Color statusColor;
    final IconData statusIcon;
    switch (status) {
      case 'Present':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle2;
        break;
      case 'Late':
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
        break;
      case 'On Leave':
        statusColor = Colors.purple;
        statusIcon = LucideIcons.calendarOff;
        break;
      case 'Absent':
      default:
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
        break;
    }

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
  const _TeacherReportRow({required this.row, required this.month, required this.instituteId});
  final Map<String, dynamic> row;
  final String month;
  final String instituteId;

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
    final total = row['total'] as int? ?? 0;
    final rate = row['rate'] as int? ?? 0;

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
            child: Text(name[0].toUpperCase(), style: TextStyle(color: colors.primary)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: typography.bodyMediumSemiBold),
                Text(employeeId, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                const Gap(6),
                Row(children: [
                  _StatChip(label: 'P', value: present, color: Colors.green),
                  const Gap(6),
                  if (late > 0) _StatChip(label: 'L', value: late, color: Colors.orange),
                  if (late > 0) const Gap(6),
                  _StatChip(label: 'A', value: absent, color: Colors.red),
                  const Gap(6),
                  Text('/ $total days', style: typography.caption.copyWith(color: colors.textSecondary)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _rateColor(rate).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$rate%',
              style: TextStyle(color: _rateColor(rate), fontWeight: FontWeight.bold),
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
  });
  final String teacherId;
  final String teacherName;
  final String month;
  final String instituteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final async = ref.watch(_teacherDaysProvider(
      _TeacherDaysParams(teacherId: teacherId, month: month, instituteId: instituteId),
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
          Text('Attendance — $month', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
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
                    final label = date != null ? DateFormat('EEE, dd MMM yyyy').format(date) : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Expanded(child: Text(label, style: typography.bodyMedium)),
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
