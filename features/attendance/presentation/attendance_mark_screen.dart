import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:abm_madrasa/features/attendance/domain/attendance_model.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_controller.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:abm_madrasa/core/utils/web_download.dart';

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
  bool _saving = false;

  // Saves the current roster with a busy state + error handling, so a failed
  // save surfaces a friendly message instead of failing silently, and the
  // button can't be double-tapped mid-save.
  Future<void> _saveRecords({required String markedBy, String? classroomName}) async {
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(_selectedType == 'Teacher'
              ? 'Teacher attendance saved successfully'
              : 'Student attendance saved successfully'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
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
    final targetName = isStudent ? (_selectedClassroom ?? 'Classroom') : 'Teachers';
    final presentCount = records.where((r) => r.status == AttendanceStatus.present).length;
    final absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateCount = records.where((r) => r.status == AttendanceStatus.late).length;

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
                  pw.Text('Attendance Sheet — $targetName',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    isStudent
                        ? 'Date: $dateStr  |  Shift: $_selectedShift'
                        : 'Date: $dateStr',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Total: ${records.length}  |  P: $presentCount  |  A: $absentCount  |  L: $lateCount',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: isStudent
                ? ['#', 'Roll / Adm No', 'Student Name', 'Status', 'Remarks / Signature']
                : ['#', 'Emp ID', 'Teacher Name', 'Status', 'Remarks / Signature'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            data: List.generate(records.length, (i) {
              final r = records[i];
              final id = isStudent ? (r.admissionNumber ?? '') : (r.employeeId ?? '');
              final name = isStudent ? (r.studentName ?? '') : (r.teacherName ?? '');
              final statusStr = r.status.name[0].toUpperCase() + r.status.name.substring(1);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
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
        final statusStr = r.status.name[0].toUpperCase() + r.status.name.substring(1);
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
        final statusStr = r.status.name[0].toUpperCase() + r.status.name.substring(1);
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
        text: 'Attendance sheet — $targetName ($dateKey)',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  void _showDownloadOptions(BuildContext context, List<AttendanceModel> records) {
    final colors = context.colors;
    final typography = context.typography;
    final isStudent = _selectedType == 'Student';
    final targetName = isStudent ? (_selectedClassroom ?? 'Classroom') : 'Teachers';
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

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
                        Text('Download Attendance Sheet', style: typography.h4),
                        Text(
                          '$targetName  •  $dateStr',
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
                    _exportAttendanceSheetPdf(records);
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
                              Text('Printable PDF Roster', style: typography.bodyMediumSemiBold),
                              const Gap(2),
                              Text('Ready to print or save for offline attendance marking',
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
                    _exportAttendanceSheetExcel(records);
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
                              Text('Excel Spreadsheet (.xlsx)', style: typography.bodyMediumSemiBold),
                              const Gap(2),
                              Text('Formatted spreadsheet with all current attendance statuses',
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

  /// Chooses an accurate empty-state icon + message: distinguishes "no class
  /// scheduled on this date" from "class is scheduled but nobody is enrolled".
  ({IconData icon, String message}) _emptyState(List<String> scheduled, String? classroom) {
    if (_searchQuery.trim().isNotEmpty) {
      return (icon: LucideIcons.search, message: 'No results match your search.');
    }
    if (_selectedType == 'Teacher') {
      return (icon: LucideIcons.calendarOff, message: 'No classes scheduled for this date.');
    }
    final cls = classroom ?? '';
    if (cls.isNotEmpty && scheduled.contains(cls)) {
      return (
        icon: LucideIcons.userX,
        message: 'No $_selectedShift students enrolled in $cls.\nAdd students to this class to mark attendance.',
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
    final allowedModules = user != null ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role) : <String>{};
    final canManageTeachers = user?.role.canAccess(AppModule.teachers, allowedModules) ?? false;
    // Teachers are date-locked to today; admins / head master may backfill.
    final canBackfill = user?.role.canBackfillAttendance ?? false;
    if (!canBackfill && _selectedDate != instituteToday()) {
      _selectedDate = instituteToday();
    }
    final classroomsAsync = ref.watch(attendanceClassroomsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: classroomsAsync.when(
        data: (classrooms) {
          if (classrooms.isNotEmpty) {
            _selectedClassroom ??= classrooms.first;
          }

          if (classrooms.isEmpty && _selectedType == 'Student') {
            return Column(
              children: [
                _AttendanceHeader(
                  selectedDate: _selectedDate,
                  selectedClassroom: null,
                  classrooms: const [],
                  user: user,
                  allowedModules: allowedModules,
                  searchQuery: _searchQuery,
                  selectedType: _selectedType,
                  selectedShift: _selectedShift,
                  onTypeChanged: (val) => setState(() => _selectedType = val),
                  onShiftChanged: (val) => setState(() => _selectedShift = val),
                  onSelectClassroom: (value) {},
                  onSearchChanged: (value) => setState(() => _searchQuery = value),
                  onMarkAllPresent: () {},
                  onSelectDate: () {},
                  dateLocked: !canBackfill,
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.school, size: 48, color: colors.textSecondary),
                        const Gap(16),
                        Text(
                          'No classrooms found',
                          style: context.typography.h3.copyWith(color: colors.textSecondary),
                        ),
                        const Gap(8),
                        Text(
                          'Add classrooms to this institute to start marking attendance.',
                          style: context.typography.bodyMedium.copyWith(color: colors.textSecondary),
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
              ],
            );
          }

          // Attendance is available for EVERY class (not just those with a
          // timetable entry that day), so newly-created classes work too.
          final scheduledClassrooms = classrooms;

          if (scheduledClassrooms.isNotEmpty && (_selectedClassroom == null || !scheduledClassrooms.contains(_selectedClassroom))) {
            _selectedClassroom = scheduledClassrooms.first;
          }

          final effectiveClassroom = _selectedType == 'Teacher' ? null : (_selectedClassroom ?? (scheduledClassrooms.isNotEmpty ? scheduledClassrooms.first : null));

          final attendanceAsync = ref.watch(
            attendanceControllerProvider(
              date: _selectedDate,
              classroom: effectiveClassroom,
              type: _selectedType,
              shift: _selectedShift,
              academicYear: _academicYear,
            ),
          );

          return Column(
            children: [
              _AttendanceHeader(
                selectedDate: _selectedDate,
                selectedClassroom: effectiveClassroom ?? '',
                classrooms: scheduledClassrooms,
                user: user,
                allowedModules: allowedModules,
                searchQuery: _searchQuery,
                selectedType: _selectedType,
                selectedShift: _selectedShift,
                onTypeChanged: (val) => setState(() => _selectedType = val),
                onShiftChanged: (val) => setState(() {
                  _selectedShift = val;
                  _selectedDate = instituteToday();
                }),
                onSelectClassroom: (value) {
                  setState(() => _selectedClassroom = value);
                },
                onSearchChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onMarkAllPresent: () async {
                  final ok = await confirmActionDialog(
                    context,
                    title: 'Mark All Present',
                    message: 'Set every listed person to Present? You can still adjust individuals before saving.',
                    confirmLabel: 'Mark All',
                    destructive: false,
                    icon: LucideIcons.checkCheck,
                  );
                  if (!ok) return;
                  ref
                      .read(
                        attendanceControllerProvider(
                          date: _selectedDate,
                          classroom: _selectedType == 'Teacher' ? null : effectiveClassroom,
                          type: _selectedType,
                          shift: _selectedShift,
                          academicYear: _academicYear,
                        ).notifier,
                      )
                      .markAll(AttendanceStatus.present);
                },
                onSelectDate: () async {
                  final today = instituteToday();
                  // Teachers are locked to today — they cannot view or mark any
                  // other day. Only admins / head master may backfill.
                  if (!canBackfill) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attendance can be marked only for today.')),
                    );
                    return;
                  }
                  // Free calendar: pick any day up to today. Days without a
                  // scheduled class just show the "No class scheduled" state,
                  // so the admin can navigate freely instead of being locked
                  // to a handful of class dates.
                  final initial = _selectedDate.isAfter(today) ? today : _selectedDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.utc(2020, 1, 1),
                    lastDate: today,
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = DateTime.utc(picked.year, picked.month, picked.day));
                  }
                },
                dateLocked: !canBackfill,
                onDownload: () => _showDownloadOptions(context, attendanceAsync.value ?? const []),
              ),
              Expanded(
                child: attendanceAsync.when(
                  data: (records) {
                    final filteredRecords = records.where((record) {
                      final query = _searchQuery.trim().toLowerCase();
                      if (query.isEmpty) {
                        return true;
                      }
                      final name = (record.studentName ?? record.teacherName ?? '').toLowerCase();
                      final id = (record.studentId ?? record.teacherId ?? '').toLowerCase();
                      return name.contains(query) || id.contains(query);
                    }).toList();

                    final presentCount = filteredRecords
                        .where((record) => record.status == AttendanceStatus.present)
                        .length;
                    final lateCount = filteredRecords
                        .where((record) => record.status == AttendanceStatus.late)
                        .length;
                    final absentCount = filteredRecords
                        .where((record) => record.status == AttendanceStatus.absent)
                        .length;

                    final empty = _emptyState(scheduledClassrooms, effectiveClassroom);

                    return Column(
                      children: [
                        Expanded(
                          child: filteredRecords.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          empty.icon,
                                          size: 42,
                                          color: colors.textSecondary.withValues(alpha: 0.5),
                                        ),
                                        const Gap(12),
                                        Text(
                                          empty.message,
                                          style: context.typography.bodyMedium.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    context.isMobile ? 14 : 20,
                                    12,
                                    context.isMobile ? 14 : 20,
                                    16,
                                  ),
                                  itemCount: filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    final record = filteredRecords[index];
                                    return _AttendanceRow(
                                      record: record,
                                      classroom: _selectedClassroom,
                                      date: _selectedDate,
                                      shift: _selectedShift,
                                      academicYear: _academicYear,
                                    );
                                  },
                                ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            context.isMobile ? 14 : 20,
                            12,
                            context.isMobile ? 14 : 20,
                            context.isMobile ? 14 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: colors.white,
                            border: Border(top: BorderSide(color: colors.border)),
                          ),
                          child: context.isMobile
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '$presentCount Present',
                                          style: context.typography.bodyMediumSemiBold.copyWith(
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const Gap(14),
                                        if (lateCount > 0)
                                          Text(
                                            '$lateCount Late',
                                            style: context.typography.bodyMediumSemiBold.copyWith(
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        if (lateCount > 0) const Gap(14),
                                        Text(
                                          '$absentCount Absent',
                                          style: context.typography.bodyMediumSemiBold.copyWith(
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showDownloadOptions(context, filteredRecords),
                                            icon: const Icon(LucideIcons.download, size: 16),
                                            label: const Text('Download'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: context.colors.primary,
                                              side: BorderSide(color: context.colors.primary.withValues(alpha: 0.35)),
                                              padding: const EdgeInsets.symmetric(vertical: 13),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Gap(10),
                                        Expanded(
                                          flex: 2,
                                          child: ABMButton(
                                            text: 'Save Records',
                                            isLoading: _saving,
                                            onPressed: () => _saveRecords(
                                              markedBy: user?.username ?? 'Admin',
                                              classroomName: _selectedType == 'Student' ? effectiveClassroom : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Text(
                                      '$presentCount Present',
                                      style: context.typography.bodyMediumSemiBold.copyWith(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const Gap(18),
                                    if (lateCount > 0)
                                      Text(
                                        '$lateCount Late',
                                        style: context.typography.bodyMediumSemiBold.copyWith(
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    if (lateCount > 0) const Gap(18),
                                    Text(
                                      '$absentCount Absent',
                                      style: context.typography.bodyMediumSemiBold.copyWith(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      onPressed: () => _showDownloadOptions(context, filteredRecords),
                                      icon: const Icon(LucideIcons.download, size: 16),
                                      label: const Text('Download Sheet'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: context.colors.primary,
                                        side: BorderSide(color: context.colors.primary.withValues(alpha: 0.35)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    const Gap(12),
                                    SizedBox(
                                      width: 170,
                                      child: ABMButton(
                                        text: 'Save Records',
                                        isLoading: _saving,
                                        onPressed: () => _saveRecords(
                                          markedBy: user?.username ?? 'Admin',
                                          classroomName: _selectedType == 'Student' ? effectiveClassroom : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text(friendlyErrorMessage(err))),
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

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({
    required this.selectedDate,
    required this.selectedClassroom,
    required this.classrooms,
    required this.user,
    required this.allowedModules,
    required this.searchQuery,
    required this.selectedType,
    required this.selectedShift,
    required this.onTypeChanged,
    required this.onShiftChanged,
    required this.onSelectClassroom,
    required this.onSearchChanged,
    required this.onMarkAllPresent,
    required this.onSelectDate,
    this.dateLocked = false,
    this.onDownload,
  });

  final DateTime selectedDate;
  final String? selectedClassroom;
  final List<String> classrooms;
  final UserModel? user;
  final Set<String> allowedModules;
  final String searchQuery;
  final String selectedType;
  final String selectedShift;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onShiftChanged;
  final ValueChanged<String> onSelectClassroom;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onSelectDate;
  final bool dateLocked;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMobile = context.isMobile;
    final filterCardPadding = isMobile ? 10.0 : 12.0;
    final sectionGap = isMobile ? 8.0 : 12.0;
    final canManageTeachers = user?.role.canAccess(AppModule.teachers, allowedModules) ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: abmGreenGradient(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AbmPatternPainter(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 20,
              MediaQuery.of(context).padding.top + (isMobile ? 6 : 12),
              isMobile ? 14 : 20,
              isMobile ? 10 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: abmGold(context),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'Attendance',
                      style: typography.h3.copyWith(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 24,
                      ),
                    ),
                    const Spacer(),
                    if (onDownload != null)
                      IconButton(
                        onPressed: onDownload,
                        icon: const Icon(LucideIcons.download, color: Colors.white),
                        tooltip: 'Download Attendance Sheet',
                      ),
                    IconButton(
                      onPressed: () => context.push(
                        selectedType == 'Teacher'
                            ? RouteNames.teacherAttendanceReport
                            : RouteNames.studentAttendanceReport,
                      ),
                      icon: const Icon(LucideIcons.barChart2, color: Colors.white70),
                      tooltip: 'View Reports',
                    ),
                    if (!isMobile) const SizedBox(width: 76),
                    if (user != null && isMobile)
                      Text(
                        user!.role.label,
                        style: typography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
                Gap(sectionGap),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: typography.bodyMedium.copyWith(
                      color: const Color(0xFF163D32),
                    ),
                    decoration: InputDecoration(
                      hintText: selectedType == 'Teacher' ? 'Search teacher...' : 'Search student...',
                      hintStyle: typography.bodyMedium.copyWith(
                        color: const Color(0xFF8B928F),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF7D857F),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 10 : 14,
                      ),
                    ),
                  ),
                ),
                Gap(sectionGap),
                Container(
                  padding: EdgeInsets.all(filterCardPadding),
                  decoration: BoxDecoration(
                    color: colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (canManageTeachers)
                        Row(
                          children: [
                            Expanded(
                              child: _TypeToggleTab(
                                title: 'Students',
                                isSelected: selectedType == 'Student',
                                onTap: () => onTypeChanged('Student'),
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: _TypeToggleTab(
                                title: 'Teachers',
                                isSelected: selectedType == 'Teacher',
                                onTap: () => onTypeChanged('Teacher'),
                              ),
                            ),
                          ],
                        ),
                      if (canManageTeachers)
                        Gap(isMobile ? 12 : 18),
                      if (selectedType == 'Student') ...[
                        _HeaderTile(
                          title: 'CLASS / SECTION',
                          child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedClassroom,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            iconEnabledColor: const Color(0xFF7A837E),
                            style: typography.bodyMediumSemiBold.copyWith(
                              color: const Color(0xFF163D32),
                            ),
                            items: classrooms
                                .map(
                                    (classroom) => DropdownMenuItem(
                                      value: classroom,
                                      child: Text(
                                        classroom,
                                        style: typography.bodyMediumSemiBold.copyWith(
                                          color: const Color(0xFF163D32),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  onSelectClassroom(value);
                                }
                              },
                            ),
                          ),
                        ),
                        Gap(isMobile ? 8 : 14),
                      ],
                      _HeaderTile(
                        title: 'SHIFT',
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedShift,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            iconEnabledColor: const Color(0xFF7A837E),
                            style: typography.bodyMediumSemiBold.copyWith(
                              color: const Color(0xFF163D32),
                            ),
                            items: ['Shift-1', 'Shift-2']
                                .map(
                                  (shift) => DropdownMenuItem(
                                    value: shift,
                                    child: Text(
                                      shift,
                                      style: typography.bodyMediumSemiBold.copyWith(
                                        color: const Color(0xFF163D32),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                onShiftChanged(value);
                              }
                            },
                          ),
                        ),
                      ),
                      Gap(isMobile ? 8 : 14),
                      _HeaderTile(
                        title: 'DATE',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onSelectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6B64C).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD6B64C).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 16,
                                    color: const Color(0xFF163D32),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEE, dd MMM yyyy').format(selectedDate),
                                      style: typography.bodyMediumSemiBold.copyWith(
                                        color: const Color(0xFF163D32),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    dateLocked ? LucideIcons.lock : LucideIcons.chevronDown,
                                    size: 16,
                                    color: const Color(0xFF163D32),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(sectionGap),
                Row(
                  children: [
                    Text(
                      selectedType == 'Teacher' ? 'Teachers Attendance' : 'Students Attendance',
                      style: typography.bodyLargeSemiBold.copyWith(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 22,
                      ),
                    ),
                    const Spacer(),
                    if (onDownload != null) ...[
                      InkWell(
                        onTap: onDownload,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 14,
                            vertical: isMobile ? 7 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.download,
                                size: 15,
                                color: Colors.white,
                              ),
                              if (!isMobile) ...[
                                const Gap(6),
                                Text(
                                  'Download',
                                  style: typography.bodyMediumSemiBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Gap(10),
                    ],
                    InkWell(
                      onTap: onMarkAllPresent,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 14,
                          vertical: isMobile ? 7 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6B64C).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFD6B64C).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.done_all,
                              size: 16,
                              color: Color(0xFFD6B64C),
                            ),
                            if (!isMobile) ...[
                              const Gap(8),
                              Text(
                                'Mark All Present',
                                style: typography.bodyMediumSemiBold.copyWith(
                                  color: const Color(0xFFD6B64C),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTile extends StatelessWidget {
  const _HeaderTile({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 12 : 14,
        vertical: context.isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(context.isMobile ? 14 : 16),
        border: Border.all(color: const Color(0xFFE7E3D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typography.caption.copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A8A81),
            ),
          ),
          Gap(context.isMobile ? 4 : 8),
          DefaultTextStyle(
            style: typography.bodyMediumSemiBold.copyWith(
              color: const Color(0xFF163D32),
              fontSize: context.isMobile ? 14 : null,
            ),
            child: IconTheme(
              data: const IconThemeData(color: Color(0xFF7A837E)),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends ConsumerWidget {
  const _AttendanceRow({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    const rowTitleColor = Color(0xFF163D32);
    const rowSubtleColor = Color(0xFF6F7A75);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(context.isMobile ? 9 : 12),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.isMobile ? 22 : 24,
            backgroundColor: const Color(0xFFE8EFEA),
            child: Text(
              ((record.teacherId != null && record.teacherId!.isNotEmpty)
                  ? record.teacherName
                  : record.studentName)?.isNotEmpty == true
                  ? ((record.teacherId != null && record.teacherId!.isNotEmpty)
                      ? record.teacherName!
                      : record.studentName!)[0].toUpperCase()
                  : '?',
              style: context.typography.bodyMediumSemiBold.copyWith(
                color: colors.primary,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (record.teacherId != null && record.teacherId!.isNotEmpty)
                      ? (record.teacherName ?? 'Unknown Teacher')
                      : (record.studentName ?? 'Unknown Student'),
                  style: context.typography.bodyMediumSemiBold.copyWith(
                    color: rowTitleColor,
                    fontSize: context.isMobile ? 14 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(3),
                Builder(builder: (context) {
                  final isTeacher = record.teacherId != null && record.teacherId!.isNotEmpty;
                  if (!isTeacher) {
                    return Text(
                      'Adm: ${record.admissionNumber?.isNotEmpty == true ? record.admissionNumber : record.studentId ?? 'N/A'}',
                      style: context.typography.bodySmall.copyWith(color: rowSubtleColor, fontSize: context.isMobile ? 12 : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  final emp = record.employeeId?.isNotEmpty == true ? record.employeeId! : '—';
                  // createdAt is stored UTC; show it in institute (Saudi, UTC+3) time.
                  final ct = record.createdAt;
                  final timeStr = ct != null ? ' · marked ${DateFormat('h:mm a').format(ct.add(const Duration(hours: 3)))}' : '';
                  final notMarked = record.id == null || record.id!.isEmpty;
                  return Row(
                    children: [
                      Flexible(
                        child: Text(
                          'ID: $emp$timeStr',
                          style: context.typography.bodySmall.copyWith(color: rowSubtleColor, fontSize: context.isMobile ? 12 : null),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (notMarked) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEEDE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Not marked',
                            style: context.typography.bodySmall.copyWith(
                              color: const Color(0xFFC77B0A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          _StatusSwitch(
            status: record.status,
            onChanged: (status) {
              final isTeacher = record.teacherId != null && record.teacherId!.isNotEmpty;
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
                  .updateStatus(targetId, status, type: isTeacher ? 'Teacher' : 'Student');
            },
          ),
        ],
      ),
    );
  }
}

class _TypeToggleTab extends StatelessWidget {
  const _TypeToggleTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD6B64C) : const Color(0xFFF8F7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD6B64C) : const Color(0xFFE7E3D7),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: typography.bodyMediumSemiBold.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF8A8A81),
          ),
        ),
      ),
    );
  }
}

class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({required this.status, required this.onChanged});

  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchChip(
            color: colors.green,
            icon: LucideIcons.check,
            label: 'P',
            tooltip: 'Present',
            selected: status == AttendanceStatus.present,
            onTap: () => onChanged(AttendanceStatus.present),
          ),
          const Gap(6),
          _SwitchChip(
            color: colors.warning,
            icon: LucideIcons.clock,
            label: 'L',
            tooltip: 'Late',
            selected: status == AttendanceStatus.late,
            onTap: () => onChanged(AttendanceStatus.late),
          ),
          const Gap(6),
          _SwitchChip(
            color: colors.red,
            icon: LucideIcons.x,
            label: 'A',
            tooltip: 'Absent',
            selected: status == AttendanceStatus.absent,
            onTap: () => onChanged(AttendanceStatus.absent),
          ),
        ],
      ),
    );
  }
}

class _SwitchChip extends StatelessWidget {
  const _SwitchChip({
    required this.color,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : color;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          constraints: const BoxConstraints(minWidth: 46),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: selected ? color : color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const Gap(4),
              Text(
                label,
                style: context.typography.bodySmallSemiBold.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
