import 'dart:io';

import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/theme/color/color_palatte.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';
import 'package:abm_madrasa/core/utils/web_download.dart';
import 'package:abm_madrasa/features/attendance/domain/attendance_model.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_controller.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceMarkScreen extends ConsumerStatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  ConsumerState<AttendanceMarkScreen> createState() =>
      _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends ConsumerState<AttendanceMarkScreen> {
  DateTime _selectedDate = instituteToday();
  String? _selectedClassroom;
  final String _academicYear = '2026-2027';
  String _searchQuery = '';
  String _selectedType = 'Student';
  String _selectedShift = 'Shift-1';
  String _selectedStatusFilter = 'All'; // 'All' | 'Present' | 'Late' | 'Absent'
  bool _saving = false;

  Future<void> _saveRecords({
    required String markedBy,
    String? classroomName,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.colors.green;
    try {
      await ref
          .read(
            attendanceControllerProvider(
              date: _selectedDate,
              classroom: _selectedType == 'Teacher' ? null : _selectedClassroom,
              type: _selectedType,
              shift: _selectedShift,
              academicYear: _academicYear,
            ).notifier,
          )
          .saveAttendance(markedBy, classroomName: classroomName);
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
              const Gap(10),
              Expanded(
                child: Text(
                  _selectedType == 'Teacher'
                      ? 'Teacher attendance saved successfully'
                      : 'Student attendance saved successfully',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportAttendanceSheetPdf(List<AttendanceModel> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance records to export.')),
      );
      return;
    }

    final isStudent = _selectedType == 'Student';
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final targetName =
        isStudent ? (_selectedClassroom ?? 'Classroom') : 'Teachers';
    final presentCount =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final absentCount =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateCount =
        records.where((r) => r.status == AttendanceStatus.late).length;

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Attendance Sheet — $targetName',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    isStudent
                        ? 'Date: $dateStr  |  Shift: $_selectedShift'
                        : 'Date: $dateStr',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Total: ${records.length}  |  P: $presentCount  |  A: $absentCount  |  L: $lateCount',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: isStudent
                ? [
                    '#',
                    'Roll / Adm No',
                    'Student Name',
                    'Status',
                    'Remarks / Signature',
                  ]
                : [
                    '#',
                    'Emp ID',
                    'Teacher Name',
                    'Status',
                    'Remarks / Signature',
                  ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 5,
            ),
            data: List.generate(records.length, (i) {
              final r = records[i];
              final id = isStudent
                  ? (r.admissionNumber ?? '')
                  : (r.employeeId ?? '');
              final name =
                  isStudent ? (r.studentName ?? '') : (r.teacherName ?? '');
              final statusStr =
                  r.status.name[0].toUpperCase() + r.status.name.substring(1);
              return [
                '${i + 1}',
                id,
                name,
                statusStr,
                r.remarks ?? '',
              ];
            }),
          ),
        ],
      ),
    );

    try {
      final bytes = await pdf.save();
      final fname = 'attendance_${targetName}_$dateKey.pdf';
      if (kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) => bytes, name: fname);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fname, bounds: origin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _exportAttendanceSheetExcel(List<AttendanceModel> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance records to export.')),
      );
      return;
    }

    final isStudent = _selectedType == 'Student';
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final targetName = isStudent ? (_selectedClassroom ?? 'Class') : 'Teachers';
    final fname = 'attendance_${targetName}_$dateKey.xlsx';
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];

    if (isStudent) {
      sheet.appendRow([
        TextCellValue('#'),
        TextCellValue('Admission No'),
        TextCellValue('Student Name'),
        TextCellValue('Classroom'),
        TextCellValue('Shift'),
        TextCellValue('Date'),
        TextCellValue('Status'),
        TextCellValue('Remarks'),
      ]);
      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        final statusStr =
            r.status.name[0].toUpperCase() + r.status.name.substring(1);
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(r.admissionNumber ?? ''),
          TextCellValue(r.studentName ?? ''),
          TextCellValue(_selectedClassroom ?? ''),
          TextCellValue(_selectedShift),
          TextCellValue(dateKey),
          TextCellValue(statusStr),
          TextCellValue(r.remarks ?? ''),
        ]);
      }
    } else {
      sheet.appendRow([
        TextCellValue('#'),
        TextCellValue('Employee ID'),
        TextCellValue('Teacher Name'),
        TextCellValue('Date'),
        TextCellValue('Status'),
        TextCellValue('Remarks'),
      ]);
      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        final statusStr =
            r.status.name[0].toUpperCase() + r.status.name.substring(1);
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(r.employeeId ?? ''),
          TextCellValue(r.teacherName ?? ''),
          TextCellValue(dateKey),
          TextCellValue(statusStr),
          TextCellValue(r.remarks ?? ''),
        ]);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    if (kIsWeb) {
      triggerBrowserDownload(
        bytes,
        fname,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded $fname')),
        );
      }
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fname');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: fname,
          ),
        ],
        text: 'Attendance sheet — $targetName ($dateKey)',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  void _showDownloadOptions(
    BuildContext context,
    List<AttendanceModel> records,
  ) {
    final colors = context.colors;
    final typography = context.typography;
    final isStudent = _selectedType == 'Student';
    final targetName =
        isStudent ? (_selectedClassroom ?? 'Classroom') : 'Teachers';
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.white,
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
                    child: Icon(
                      LucideIcons.downloadCloud,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Attendance Sheet', style: typography.h4),
                        Text(
                          '$targetName  •  $dateStr',
                          style: typography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
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
                    _exportAttendanceSheetPdf(records);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
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
                          child: const Icon(
                            LucideIcons.fileText,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Printable PDF Roster',
                                style: typography.bodyMediumSemiBold,
                              ),
                              const Gap(2),
                              Text(
                                'Ready to print or save for offline attendance records',
                                style: typography.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: Colors.grey,
                        ),
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
                    _exportAttendanceSheetExcel(records);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
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
                          child: const Icon(
                            LucideIcons.table,
                            color: Colors.green,
                            size: 22,
                          ),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Excel Spreadsheet (.xlsx)',
                                style: typography.bodyMediumSemiBold,
                              ),
                              const Gap(2),
                              Text(
                                'Formatted spreadsheet with statuses and remarks',
                                style: typography.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: Colors.grey,
                        ),
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

  void _showClassroomPickerSheet(
    BuildContext context,
    List<String> classrooms,
    String? current,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = classrooms
                .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.graduationCap,
                            color: context.colors.primary,
                            size: 20,
                          ),
                        ),
                        const Gap(12),
                        Text('Select Class / Section', style: context.typography.h4),
                      ],
                    ),
                    const Gap(14),
                    TextField(
                      onChanged: (val) => setSheetState(() => query = val),
                      decoration: InputDecoration(
                        hintText: 'Search classroom...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final cls = filtered[index];
                          final isSelected = cls == current;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedClassroom = cls);
                              Navigator.of(ctx).pop();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.colors.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? context.colors.primary.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    cls,
                                    style: context.typography.bodyMediumSemiBold
                                        .copyWith(
                                      color: isSelected
                                          ? context.colors.primary
                                          : const Color(0xFF163D32),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    Icon(
                                      LucideIcons.check,
                                      size: 18,
                                      color: context.colors.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  ({IconData icon, String message}) _emptyState(
    List<String> scheduled,
    String? classroom,
  ) {
    if (_searchQuery.trim().isNotEmpty) {
      return (
        icon: LucideIcons.search,
        message: 'No students match "$_searchQuery"',
      );
    }
    if (_selectedStatusFilter != 'All') {
      return (
        icon: LucideIcons.filter,
        message: 'No students marked as $_selectedStatusFilter in this class.',
      );
    }
    if (_selectedType == 'Teacher') {
      return (
        icon: LucideIcons.calendarOff,
        message: 'No teachers found for $_selectedShift on this date.',
      );
    }
    final cls = classroom ?? '';
    if (cls.isNotEmpty && scheduled.contains(cls)) {
      return (
        icon: LucideIcons.userX,
        message:
            'No $_selectedShift students enrolled in $cls.\nAdd students to this class to mark attendance.',
      );
    }
    return (
      icon: LucideIcons.calendarOff,
      message: 'No class scheduled${cls.isEmpty ? '' : ' for $cls'} on this date.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final allowedModules = user != null
        ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role)
        : <String>{};
    final canManageTeachers =
        user?.role.canAccess(AppModule.teachers, allowedModules) ?? false;
    final canBackfill = user?.role.canBackfillAttendance ?? false;
    if (!canBackfill && _selectedDate != instituteToday()) {
      _selectedDate = instituteToday();
    }
    final classroomsAsync = ref.watch(attendanceClassroomsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: classroomsAsync.when(
        data: (classrooms) {
          if (classrooms.isNotEmpty) {
            _selectedClassroom ??= classrooms.first;
          }

          if (classrooms.isEmpty && _selectedType == 'Student') {
            return Column(
              children: [
                _AttendanceCompactHeader(
                  selectedDate: _selectedDate,
                  selectedClassroom: null,
                  classrooms: const [],
                  user: user,
                  allowedModules: allowedModules,
                  selectedType: _selectedType,
                  selectedShift: _selectedShift,
                  onTypeChanged: (val) => setState(() => _selectedType = val),
                  onShiftChanged: (val) => setState(() => _selectedShift = val),
                  onOpenClassroomPicker: () {},
                  onMarkAllPresent: () {},
                  onSelectDate: () {},
                  dateLocked: !canBackfill,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.school,
                              size: 44,
                              color: colors.primary,
                            ),
                          ),
                          const Gap(16),
                          Text(
                            'No classrooms found',
                            style: context.typography.h3.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Add classrooms to this institute to start marking attendance.',
                            style: context.typography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Gap(24),
                          if (canManageTeachers)
                            ABMButton(
                              text: 'Manage Classrooms',
                              icon: LucideIcons.layers,
                              onPressed: () => context.go(RouteNames.classrooms),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final scheduledClassrooms = classrooms;
          if (scheduledClassrooms.isNotEmpty &&
              (_selectedClassroom == null ||
                  !scheduledClassrooms.contains(_selectedClassroom))) {
            _selectedClassroom = scheduledClassrooms.first;
          }

          final effectiveClassroom = _selectedType == 'Teacher'
              ? null
              : (_selectedClassroom ??
                  (scheduledClassrooms.isNotEmpty
                      ? scheduledClassrooms.first
                      : null));

          final attendanceAsync = ref.watch(
            attendanceControllerProvider(
              date: _selectedDate,
              classroom: effectiveClassroom,
              type: _selectedType,
              shift: _selectedShift,
              academicYear: _academicYear,
            ),
          );

          Future<void> handleMarkAllPresent() async {
            final ok = await confirmActionDialog(
              context,
              title: 'Mark All Present',
              message:
                  'Set every listed person to Present? You can still adjust individuals before saving.',
              confirmLabel: 'Mark All',
              destructive: false,
              icon: LucideIcons.checkCheck,
            );
            if (!ok) return;
            ref
                .read(
                  attendanceControllerProvider(
                    date: _selectedDate,
                    classroom: _selectedType == 'Teacher'
                        ? null
                        : effectiveClassroom,
                    type: _selectedType,
                    shift: _selectedShift,
                    academicYear: _academicYear,
                  ).notifier,
                )
                .markAll(AttendanceStatus.present);
            HapticFeedback.lightImpact();
          }

          return Column(
            children: [
              _AttendanceCompactHeader(
                selectedDate: _selectedDate,
                selectedClassroom: effectiveClassroom ?? '',
                classrooms: scheduledClassrooms,
                user: user,
                allowedModules: allowedModules,
                selectedType: _selectedType,
                selectedShift: _selectedShift,
                onTypeChanged: (val) => setState(() {
                  _selectedType = val;
                  _selectedStatusFilter = 'All';
                }),
                onShiftChanged: (val) => setState(() {
                  _selectedShift = val;
                  _selectedDate = instituteToday();
                }),
                onOpenClassroomPicker: () => _showClassroomPickerSheet(
                  context,
                  scheduledClassrooms,
                  effectiveClassroom,
                ),
                onMarkAllPresent: handleMarkAllPresent,
                onSelectDate: () async {
                  final today = instituteToday();
                  if (!canBackfill) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attendance can be marked only for today.'),
                      ),
                    );
                    return;
                  }
                  final initial =
                      _selectedDate.isAfter(today) ? today : _selectedDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.utc(2020, 1, 1),
                    lastDate: today,
                  );
                  if (picked != null) {
                    setState(
                      () => _selectedDate = DateTime.utc(
                        picked.year,
                        picked.month,
                        picked.day,
                      ),
                    );
                  }
                },
                dateLocked: !canBackfill,
                onDownload: () => _showDownloadOptions(
                  context,
                  attendanceAsync.value ?? const [],
                ),
              ),
              Expanded(
                child: attendanceAsync.when(
                  data: (records) {
                    final query = _searchQuery.trim().toLowerCase();
                    final searchedRecords = records.where((record) {
                      if (query.isEmpty) return true;
                      final name = (record.studentName ??
                              record.teacherName ??
                              '')
                          .toLowerCase();
                      final id = (record.studentId ??
                              record.teacherId ??
                              record.admissionNumber ??
                              record.employeeId ??
                              '')
                          .toLowerCase();
                      return name.contains(query) || id.contains(query);
                    }).toList();

                    final presentCount = records
                        .where((r) => r.status == AttendanceStatus.present)
                        .length;
                    final lateCount = records
                        .where((r) => r.status == AttendanceStatus.late)
                        .length;
                    final absentCount = records
                        .where((r) => r.status == AttendanceStatus.absent)
                        .length;
                    final totalCount = records.length;

                    final filteredRecords = searchedRecords.where((record) {
                      if (_selectedStatusFilter == 'Present') {
                        return record.status == AttendanceStatus.present;
                      }
                      if (_selectedStatusFilter == 'Late') {
                        return record.status == AttendanceStatus.late;
                      }
                      if (_selectedStatusFilter == 'Absent') {
                        return record.status == AttendanceStatus.absent;
                      }
                      return true;
                    }).toList();

                    final empty =
                        _emptyState(scheduledClassrooms, effectiveClassroom);

                    return Column(
                      children: [
                        // Live Filter & Search Control Row
                        _AttendanceControlBar(
                          isTeacher: _selectedType == 'Teacher',
                          searchQuery: _searchQuery,
                          onSearchChanged: (val) =>
                              setState(() => _searchQuery = val),
                          totalCount: totalCount,
                          presentCount: presentCount,
                          lateCount: lateCount,
                          absentCount: absentCount,
                          selectedFilter: _selectedStatusFilter,
                          onFilterSelected: (filter) =>
                              setState(() => _selectedStatusFilter = filter),
                          onMarkAllPresent: handleMarkAllPresent,
                        ),

                        // Student List
                        Expanded(
                          child: filteredRecords.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.04,
                                                ),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            empty.icon,
                                            size: 38,
                                            color: colors.textSecondary
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const Gap(14),
                                        Text(
                                          empty.message,
                                          style: context.typography.bodyMedium
                                              .copyWith(
                                            color: colors.textSecondary,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_searchQuery.isNotEmpty ||
                                            _selectedStatusFilter != 'All') ...[
                                          const Gap(14),
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _searchQuery = '';
                                                _selectedStatusFilter = 'All';
                                              });
                                            },
                                            icon: const Icon(
                                              LucideIcons.xCircle,
                                              size: 16,
                                            ),
                                            label: const Text('Clear Filters'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    context.isMobile ? 12 : 20,
                                    10,
                                    context.isMobile ? 12 : 20,
                                    100, // Keep bottom list items clear of floating save bar
                                  ),
                                  itemCount: filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    final record = filteredRecords[index];
                                    return _AttendanceCard(
                                      key: ValueKey(
                                        record.studentId ??
                                            record.teacherId ??
                                            '$index',
                                      ),
                                      record: record,
                                      classroom: _selectedClassroom,
                                      date: _selectedDate,
                                      shift: _selectedShift,
                                      academicYear: _academicYear,
                                    );
                                  },
                                ),
                        ),

                        // Floating Bottom Action Bar
                        _AttendanceBottomBar(
                          presentCount: presentCount,
                          lateCount: lateCount,
                          absentCount: absentCount,
                          totalCount: totalCount,
                          saving: _saving,
                          onDownload: () => _showDownloadOptions(
                            context,
                            filteredRecords,
                          ),
                          onSave: () => _saveRecords(
                            markedBy: user?.username ?? 'Admin',
                            classroomName: _selectedType == 'Student'
                                ? effectiveClassroom
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        friendlyErrorMessage(err),
                        textAlign: TextAlign.center,
                        style: context.typography.bodyMedium.copyWith(
                          color: colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(friendlyErrorMessage(err))),
      ),
    );
  }
}

/// Compact, ultra-clean header for Attendance
class _AttendanceCompactHeader extends StatelessWidget {
  const _AttendanceCompactHeader({
    required this.selectedDate,
    required this.selectedClassroom,
    required this.classrooms,
    required this.user,
    required this.allowedModules,
    required this.selectedType,
    required this.selectedShift,
    required this.onTypeChanged,
    required this.onShiftChanged,
    required this.onOpenClassroomPicker,
    required this.onMarkAllPresent,
    required this.onSelectDate,
    required this.dateLocked,
    this.onDownload,
  });

  final DateTime selectedDate;
  final String? selectedClassroom;
  final List<String> classrooms;
  final UserModel? user;
  final Set<String> allowedModules;
  final String selectedType;
  final String selectedShift;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onShiftChanged;
  final VoidCallback onOpenClassroomPicker;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onSelectDate;
  final bool dateLocked;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final isMobile = context.isMobile;
    final canManageTeachers =
        user?.role.canAccess(AppModule.teachers, allowedModules) ?? false;

    // Formatting date cleanly
    final dateFormatted = DateFormat(isMobile ? 'd MMM' : 'EEE, d MMM')
        .format(selectedDate);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: abmGreenGradient(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AbmPatternPainter(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: isMobile ? 8 : 12,
                bottom: isMobile ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Title & Quick Action (scoped horizontal clearance for shell overlay buttons)
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 64 : 20,
                      right: isMobile ? 116 : 20,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance',
                                style: typography.h3.copyWith(
                                  color: Colors.white,
                                  fontSize: isMobile ? 21 : 25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                selectedType == 'Student'
                                    ? 'Student Roster • $selectedShift'
                                    : 'Teacher Attendance • $selectedShift • $dateFormatted',
                                style: typography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: isMobile ? 12 : 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => context.push(
                            selectedType == 'Teacher'
                                ? RouteNames.teacherAttendanceReport
                                : RouteNames.studentAttendanceReport,
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.barChart3,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                          tooltip: 'View Reports',
                        ),
                      ],
                    ),
                  ),

                  // Mode Toggle (Students / Teachers) - only shown if permitted
                  if (canManageTeachers) ...[
                    const Gap(10),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                      ),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SegmentPill(
                                title: 'Students',
                                icon: LucideIcons.graduationCap,
                                isSelected: selectedType == 'Student',
                                onTap: () => onTypeChanged('Student'),
                              ),
                            ),
                            const Gap(4),
                            Expanded(
                              child: _SegmentPill(
                                title: 'Teachers',
                                icon: LucideIcons.briefcase,
                                isSelected: selectedType == 'Teacher',
                                onTap: () => onTypeChanged('Teacher'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Gap(10),

                  // 100% visible, non-scrolling filter row across full device width
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                    ),
                    child: Row(
                      children: [
                        // Class Selector (Only for students)
                        if (selectedType == 'Student') ...[
                          Expanded(
                            flex: 11,
                            child: _HeaderFilterChip(
                              icon: LucideIcons.school,
                              label: selectedClassroom?.isNotEmpty == true
                                  ? selectedClassroom!
                                  : 'Select Class',
                              tooltip: 'Change Classroom',
                              onTap: onOpenClassroomPicker,
                            ),
                          ),
                          const Gap(8),
                        ],

                        // Shift Selector Pill
                        Expanded(
                          flex: 9,
                          child: _HeaderFilterChip(
                            icon: LucideIcons.clock,
                            label: selectedShift,
                            tooltip: 'Switch Shift',
                            onTap: () {
                              onShiftChanged(
                                selectedShift == 'Shift-1' ? 'Shift-2' : 'Shift-1',
                              );
                            },
                          ),
                        ),
                        const Gap(8),

                        // Date Selector Pill - Prominent, Highlighted, Always Visible!
                        Expanded(
                          flex: 12,
                          child: _HeaderFilterChip(
                            icon: LucideIcons.calendar,
                            label: dateFormatted,
                            trailingIcon: dateLocked
                                ? LucideIcons.lock
                                : LucideIcons.chevronDown,
                            tooltip: dateLocked
                                ? 'Locked to Today'
                                : 'Select Attendance Date',
                            highlight: true,
                            onTap: onSelectDate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segment pill tab for Students / Teachers mode
class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? ColorPalette.primary
                  : Colors.white.withValues(alpha: 0.85),
            ),
            const Gap(6),
            Text(
              title,
              style: context.typography.bodySmallSemiBold.copyWith(
                color: isSelected
                    ? ColorPalette.primary
                    : Colors.white.withValues(alpha: 0.85),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact header filter chip
class _HeaderFilterChip extends StatelessWidget {
  const _HeaderFilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingIcon = LucideIcons.chevronDown,
    this.tooltip,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final String? tooltip;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7.5),
          decoration: BoxDecoration(
            color: highlight
                ? ColorPalette.secondary.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlight
                  ? ColorPalette.secondary.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const Gap(5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodySmallSemiBold.copyWith(
                    color: Colors.white,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const Gap(3),
                Icon(
                  trailingIcon,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: chip) : chip;
  }
}

/// Control bar with Search input, interactive status tabs, and attendance progress
class _AttendanceControlBar extends StatelessWidget {
  const _AttendanceControlBar({
    this.isTeacher = false,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.totalCount,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.onMarkAllPresent,
  });

  final bool isTeacher;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final int totalCount;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback? onMarkAllPresent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 20,
        10,
        isMobile ? 12 : 20,
        4,
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: searchQuery,
                  selection: TextSelection.collapsed(offset: searchQuery.length),
                ),
              ),
              style: context.typography.bodySmallMedium.copyWith(
                color: const Color(0xFF163D32),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: isTeacher
                    ? 'Search by teacher name or employee ID...'
                    : 'Search by student name or roll number...',
                hintStyle: context.typography.bodySmall.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: colors.textSecondary,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => onSearchChanged(''),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
              ),
            ),
          ),

          const Gap(10),

          // Interactive Filter Chips Row & All Present Action
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _StatusFilterTab(
                        label: isTeacher ? 'All Staff' : 'All',
                        count: totalCount,
                        color: ColorPalette.primary,
                        isSelected: selectedFilter == 'All',
                        onTap: () => onFilterSelected('All'),
                      ),
                      const Gap(6),
                      _StatusFilterTab(
                        label: 'Present',
                        count: presentCount,
                        color: const Color(0xFF16A34A),
                        isSelected: selectedFilter == 'Present',
                        onTap: () => onFilterSelected('Present'),
                      ),
                      const Gap(6),
                      _StatusFilterTab(
                        label: 'Late',
                        count: lateCount,
                        color: const Color(0xFFD97706),
                        isSelected: selectedFilter == 'Late',
                        onTap: () => onFilterSelected('Late'),
                      ),
                      const Gap(6),
                      _StatusFilterTab(
                        label: 'Absent',
                        count: absentCount,
                        color: const Color(0xFFDC2626),
                        isSelected: selectedFilter == 'Absent',
                        onTap: () => onFilterSelected('Absent'),
                      ),
                    ],
                  ),
                ),
              ),
              if (onMarkAllPresent != null) ...[
                const Gap(8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMarkAllPresent!();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.checkCheck,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                          const Gap(4),
                          Text(
                            'All Present',
                            style: context.typography.caption.copyWith(
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Segmented Progress Bar (visual breakdown)
          if (totalCount > 0) ...[
            const Gap(8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 4,
                child: Row(
                  children: [
                    if (presentCount > 0)
                      Expanded(
                        flex: presentCount,
                        child: Container(color: const Color(0xFF16A34A)),
                      ),
                    if (lateCount > 0)
                      Expanded(
                        flex: lateCount,
                        child: Container(color: const Color(0xFFD97706)),
                      ),
                    if (absentCount > 0)
                      Expanded(
                        flex: absentCount,
                        child: Container(color: const Color(0xFFDC2626)),
                      ),
                    if (totalCount - presentCount - lateCount - absentCount > 0)
                      Expanded(
                        flex: totalCount - presentCount - lateCount - absentCount,
                        child: Container(color: Colors.grey.shade300),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Filter tab chip with badge count
class _StatusFilterTab extends StatelessWidget {
  const _StatusFilterTab({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : colors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.typography.bodySmallSemiBold.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  fontSize: 12,
                ),
              ),
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: context.typography.caption.copyWith(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Redesigned Student / Teacher attendance card
class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({
    super.key,
    required this.record,
    required this.classroom,
    required this.date,
    required this.shift,
    required this.academicYear,
  });

  final AttendanceModel record;
  final String? classroom;
  final DateTime date;
  final String shift;
  final String academicYear;

  Color _getStatusAccentColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF16A34A);
      case AttendanceStatus.late:
        return const Color(0xFFD97706);
      case AttendanceStatus.absent:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isMobile = context.isMobile;
    final isTeacher =
        record.teacherId != null && record.teacherId!.isNotEmpty;
    final name = isTeacher
        ? (record.teacherName ?? 'Unknown Teacher')
        : (record.studentName ?? 'Unknown Student');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final statusColor = _getStatusAccentColor(record.status);

    // Extracted so it can sit inline (desktop) or on its own row (mobile),
    // which frees the name column to show the full name.
    final statusSwitch = _StatusSwitch(
      status: record.status,
      onChanged: (newStatus) {
        final targetId = isTeacher ? record.teacherId! : record.studentId!;
        ref
            .read(
              attendanceControllerProvider(
                date: date,
                classroom: isTeacher ? null : classroom,
                type: isTeacher ? 'Teacher' : 'Student',
                shift: shift,
                academicYear: academicYear,
              ).notifier,
            )
            .updateStatus(
              targetId,
              newStatus,
              type: isTeacher ? 'Teacher' : 'Student',
            );
      },
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic status indicator strip on the left edge
              Container(
                width: 5,
                color: statusColor,
              ),

              // Card Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 14,
                    vertical: isMobile ? 10 : 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                      // Avatar with Initial & mini badge
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 20 : 22,
                            backgroundColor:
                                statusColor.withValues(alpha: 0.12),
                            child: Text(
                              initial,
                              style: context.typography.bodyMediumSemiBold
                                  .copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Gap(12),

                      // Student / Teacher Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: context.typography.bodyMediumSemiBold
                                  .copyWith(
                                color: const Color(0xFF163D32),
                                fontSize: isMobile ? 14.5 : 15.5,
                              ),
                              // Show the full name — wrap to a second line rather
                              // than clipping long names at ~13 chars. On mobile the
                              // status switch drops below (see layout) so the name
                              // gets the full card width.
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(3),
                            if (!isTeacher) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Adm: ${record.admissionNumber?.isNotEmpty == true ? record.admissionNumber : record.studentId ?? 'N/A'}',
                                  style: context.typography.caption.copyWith(
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Builder(
                                builder: (context) {
                                  final emp =
                                      record.employeeId?.isNotEmpty == true
                                          ? record.employeeId!
                                          : '—';
                                  final ct = record.createdAt;
                                  final timeStr = ct != null
                                      ? ' · ${DateFormat('h:mm a').format(ct.add(const Duration(hours: 3)))}'
                                      : '';
                                  final notMarked = record.id == null ||
                                      record.id!.isEmpty;

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ID: $emp$timeStr',
                                        style: context.typography.caption
                                            .copyWith(
                                          color: const Color(0xFF6B7280),
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (notMarked) ...[
                                        const Gap(6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Pending',
                                            style: context.typography.caption
                                                .copyWith(
                                              color: const Color(0xFFB45309),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Desktop: status switch sits inline to the right.
                      if (!isMobile) const Gap(10),
                      if (!isMobile) statusSwitch,
                        ],
                      ),
                      // Mobile: drop the status switch to its own row so the name
                      // above can use the full card width and show in full.
                      if (isMobile) const Gap(10),
                      if (isMobile)
                        Align(
                          alignment: Alignment.centerRight,
                          child: statusSwitch,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented Status Switcher with P, L, A buttons
class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({required this.status, required this.onChanged});

  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusButton(
            label: 'P',
            tooltip: 'Present',
            icon: LucideIcons.check,
            activeColor: const Color(0xFF16A34A),
            isSelected: status == AttendanceStatus.present,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(AttendanceStatus.present);
            },
          ),
          const Gap(4),
          _StatusButton(
            label: 'L',
            tooltip: 'Late',
            icon: LucideIcons.clock,
            activeColor: const Color(0xFFD97706),
            isSelected: status == AttendanceStatus.late,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(AttendanceStatus.late);
            },
          ),
          const Gap(4),
          _StatusButton(
            label: 'A',
            tooltip: 'Absent',
            icon: LucideIcons.x,
            activeColor: const Color(0xFFDC2626),
            isSelected: status == AttendanceStatus.absent,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(AttendanceStatus.absent);
            },
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          height: 38,
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const Gap(3),
              Text(
                label,
                style: context.typography.bodySmallSemiBold.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating / Docked Bottom Action & Summary Bar
class _AttendanceBottomBar extends StatelessWidget {
  const _AttendanceBottomBar({
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.totalCount,
    required this.saving,
    required this.onDownload,
    required this.onSave,
  });

  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int totalCount;
  final bool saving;
  final VoidCallback onDownload;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 20,
        10,
        isMobile ? 14 : 20,
        // Ensure proper bottom padding above device navigation area
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 4
            : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Metrics Summary Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '$totalCount',
                      style: context.typography.bodyLargeSemiBold.copyWith(
                        color: const Color(0xFF163D32),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' Listed',
                      style: context.typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '$presentCount P',
                      style: context.typography.caption.copyWith(
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (lateCount > 0) ...[
                      const Gap(8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '$lateCount L',
                        style: context.typography.caption.copyWith(
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const Gap(8),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '$absentCount A',
                      style: context.typography.caption.copyWith(
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Gap(10),

          // Download / Export Icon Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(
                  LucideIcons.download,
                  size: 19,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),

          const Gap(10),

          // Primary Save Records Button
          SizedBox(
            width: isMobile ? 155 : 185,
            child: ABMButton(
              text: 'Save Records',
              icon: LucideIcons.checkCheck,
              height: 46,
              fontSize: 14,
              iconSize: 17,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              isLoading: saving,
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}
