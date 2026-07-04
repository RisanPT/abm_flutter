import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/custom_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ── Providers ────────────────────────────────────────────────────────────────

class _ReportParams {
  const _ReportParams({required this.month, required this.instituteId, required this.type, this.refreshKey = 0});
  final String month;
  final String instituteId;
  final String type;
  final int refreshKey;   // increment to force re-fetch same month
  @override
  bool operator ==(Object other) =>
      other is _ReportParams &&
      month == other.month &&
      instituteId == other.instituteId &&
      type == other.type &&
      refreshKey == other.refreshKey;
  @override
  int get hashCode => Object.hash(month, instituteId, type, refreshKey);
}

final _attendanceReportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, _ReportParams>(
  (ref, params) async {
    final dio = ref.watch(dioProvider);
    final endpoint =
        params.type == 'teacher' ? '/attendance/teacher-report' : '/attendance/report';
    final response = await dio.get(endpoint, queryParameters: {
      'month': params.month,
      'instituteId': params.instituteId,
    });
    return response.data as Map<String, dynamic>;
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
  // A separate refresh counter so we can force-refetch with same month
  int _refreshKey = 0;

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedDate);
  String get _monthLabel => DateFormat('MMM yyyy').format(_selectedDate);

  Future<void> _refresh() async {
    setState(() => _refreshKey++);
    ref.invalidate(_attendanceReportProvider);
  }

  Future<void> _exportAttendancePdf() async {
    final institute = ref.read(selectedInstituteProvider);
    final isStudentTab = widget.reportType == 'student';
    final type = isStudentTab ? 'student' : 'teacher';
    final params = _ReportParams(month: _monthKey, instituteId: institute.id, type: type, refreshKey: _refreshKey);
    
    final reportAsync = ref.read(_attendanceReportProvider(params));
    if (!reportAsync.hasValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report data is still loading or not available.')),
      );
      return;
    }
    
    final data = reportAsync.value!;
    final summary = (data['summary'] as List?) ?? [];
    final studentSummary = (data['studentSummary'] as List?) ?? [];
    if (summary.isEmpty && studentSummary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance data to export for this month.')),
      );
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
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final institute = ref.watch(selectedInstituteProvider);
    final isStudent = widget.reportType == 'student';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(isStudent ? 'Student Report' : 'Teacher Report', style: typography.h3),
        actions: [
          // Refresh button
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          // Export PDF button
          IconButton(
            onPressed: _exportAttendancePdf,
            icon: const Icon(LucideIcons.download),
            tooltip: 'Export PDF',
          ),
          // Custom Month picker button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickMonth,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendar, size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _monthLabel,
                          style: typography.bodyMediumSemiBold.copyWith(color: colors.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronDown, size: 16, color: colors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isStudent
          ? _StudentReportTab(month: _monthKey, instituteId: institute.id)
          : _TeacherReportTab(month: _monthKey, instituteId: institute.id),
    );
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
}

// ── Student Report Tab ────────────────────────────────────────────────────────

class _StudentReportTab extends ConsumerWidget {
  const _StudentReportTab({required this.month, required this.instituteId});
  final String month;
  final String instituteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = _ReportParams(month: month, instituteId: instituteId, type: 'student');
    final reportAsync = ref.watch(_attendanceReportProvider(params));
    return reportAsync.when(
      data: (data) {
        final rawSummary = (data['summary'] as List?) ?? [];
        final summary = rawSummary.where((row) {
          final r = row as Map<String, dynamic>;
          final classroom = r['classroom'] as String?;
          return classroom != null && classroom.isNotEmpty && classroom.toLowerCase() != 'unknown';
        }).toList();

        final total = data['totalRecords'] as int? ?? 0;
        
        int totalPresent = 0;
        int totalAbsent = 0;
        int totalLate = 0;
        for (final row in summary) {
          final r = row as Map<String, dynamic>;
          totalPresent += (r['present'] as int?) ?? 0;
          totalAbsent += (r['absent'] as int?) ?? 0;
          totalLate += (r['late'] as int?) ?? 0;
        }

        if (summary.isEmpty) {
          return _EmptyReport(message: 'No student attendance recorded for $month.');
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SummaryCard(
              total: total,
              date: month,
              totalPresent: totalPresent,
              totalAbsent: totalAbsent,
              totalLate: totalLate,
            ),
            const Gap(20),
            Text('By Classroom', style: context.typography.h4),
            const Gap(12),
            ...summary.map((row) => _ClassroomReportRow(row: row as Map<String, dynamic>)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Teacher Report Tab ────────────────────────────────────────────────────────

class _TeacherReportTab extends ConsumerWidget {
  const _TeacherReportTab({required this.month, required this.instituteId});
  final String month;
  final String instituteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = _ReportParams(month: month, instituteId: instituteId, type: 'teacher');
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
            Text('Teacher Attendance — $month', style: context.typography.h4),
            const Gap(12),
            ...summary.map((row) => _TeacherReportRow(row: row as Map<String, dynamic>)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total, 
    required this.date,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
  });
  
  final int total;
  final String date;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF0F4A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.clipboardList, color: Colors.white, size: 28),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Institution Summary', style: typography.bodyMedium.copyWith(color: Colors.white70)),
                    Text('$total Records', style: typography.h3.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(date, style: typography.bodyMediumSemiBold.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatMetric(context, 'Present', totalPresent, Colors.greenAccent),
              _buildStatMetric(context, 'Late', totalLate, Colors.orangeAccent),
              _buildStatMetric(context, 'Absent', totalAbsent, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(BuildContext context, String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: context.typography.h3.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        Text(
          label,
          style: context.typography.bodySmallSemiBold.copyWith(color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

class _ClassroomReportRow extends StatelessWidget {
  const _ClassroomReportRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final present = row['present'] as int? ?? 0;
    final absent = row['absent'] as int? ?? 0;
    final late = row['late'] as int? ?? 0;
    final total = row['total'] as int? ?? 0;
    final rate = row['rate'] as int? ?? 0;
    final classroom = row['classroom'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(classroom, style: typography.bodyLargeSemiBold),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _rateColor(rate).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$rate%',
                  style: TextStyle(
                    color: _rateColor(rate),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total > 0 ? present / total : 0,
              backgroundColor: colors.border,
              color: _rateColor(rate),
              minHeight: 8,
            ),
          ),
          const Gap(10),
          Row(
            children: [
              _StatChip(label: 'Present', value: present, color: Colors.green),
              const Gap(8),
              if (late > 0) _StatChip(label: 'Late', value: late, color: Colors.orange),
              if (late > 0) const Gap(8),
              _StatChip(label: 'Absent', value: absent, color: Colors.red),
              const Spacer(),
              Text('Total: $total', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 85) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }
}

class _TeacherReportRow extends StatelessWidget {
  const _TeacherReportRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final name = row['fullName'] as String? ?? 'Unknown';
    final employeeId = row['employeeId'] as String? ?? '';
    final present = row['present'] as int? ?? 0;
    final absent = row['absent'] as int? ?? 0;
    final late = row['late'] as int? ?? 0;
    final total = row['total'] as int? ?? 0;
    final rate = row['rate'] as int? ?? 0;

    return Container(
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
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 85) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
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
