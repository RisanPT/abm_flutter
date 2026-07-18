import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';

import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/students/presentation/student_controller.dart';
import 'package:dio/dio.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_subjects_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';

class ClassroomManagementScreen extends ConsumerWidget {
  const ClassroomManagementScreen({super.key});

  Future<void> _exportClassroomsPdf(List<ClassroomModel> classrooms, List<StudentModel> students) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Classroom Occupancy Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Total Classrooms: ${classrooms.length}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Class Name', 'Description', 'Student Count', 'Subjects'],
            data: classrooms.map((c) {
              final count = students.where((s) => s.classroom == c.name).length;
              return [
                c.name,
                c.description ?? '',
                count.toString(),
                c.subjects.join(', '),
              ];
            }).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final classroomsAsync = ref.watch(classroomControllerProvider);
    final studentsAsync = ref.watch(studentControllerProvider);
    
    final user = ref.watch(authControllerProvider).value;
    final allowedModules = user != null ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role) : <String>{};
    final canEditAdmin = user?.role.canEditAdministration(allowedModules) ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Classroom Management',
            subtitle: 'Manage student sections and track occupancy across the madrasa.',
            showBackButton: false,
            actions: [
              if (classroomsAsync.hasValue && studentsAsync.hasValue)
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(LucideIcons.download, color: Colors.white, size: 20),
                    onPressed: () => _exportClassroomsPdf(classroomsAsync.value!, studentsAsync.value!),
                    tooltip: 'Export PDF',
                  ),
                ),
            ],
          ),
          Expanded(
            child: classroomsAsync.when(
              data: (classrooms) => studentsAsync.when(
                data: (students) => _buildGrid(context, classrooms, students),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _errorView(context, ref, e, 'students'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorView(context, ref, e, 'classrooms'),
            ),
          ),
      ]),
      floatingActionButton: canEditAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddClassDialog(context, ref),
              label: const Text('Add Classroom'),
              icon: const Icon(LucideIcons.plus),
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  /// A calm, actionable error state with a Retry — never a raw exception dump.
  Widget _errorView(BuildContext context, WidgetRef ref, Object error, String what) {
    final colors = context.colors;
    final typography = context.typography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: colors.red.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(LucideIcons.alertTriangle, size: 38, color: colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load $what",
              style: typography.h3.copyWith(color: const Color(0xFF163D32)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _friendlyError(error),
              style: typography.bodyMedium.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(classroomControllerProvider);
                ref.invalidate(studentControllerProvider);
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Turns a raw error (usually a Dio 4xx/5xx) into a short, human sentence.
  static String _friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final m = data['message'].toString();
        if (m.contains('E11000') || m.toLowerCase().contains('duplicate')) {
          return 'A classroom with that name already exists — try a different name.';
        }
        return m;
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return 'Cannot reach the server. Check that the backend is running, then retry.';
        default:
          break;
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Widget _buildGrid(BuildContext context, List classrooms, List students) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 1 : (MediaQuery.of(context).size.width > 1200 ? 3 : 2),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.4,
      ),
      itemCount: classrooms.length,
      itemBuilder: (context, index) {
        final classroom = classrooms[index];
        final count = students.where((s) => s.classroom == classroom.name).length;


        return ClassroomCard(
          title: classroom.name,
          studentCount: count,
          shift: classroom.shift,
          onViewStudents: () => context.push(RouteNames.students, extra: classroom.name),
          onManageSubjects: () => showDialog(
            context: context,
            builder: (context) => ClassroomSubjectsDialog(classroom: classroom),
          ),
          onManageTimetable: () => context.push(RouteNames.timetable),
        );
      },
    );
  }

  Future<void> _showAddClassDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    var selectedShift = 'Shift-1';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setLocalState) => AlertDialog(
          title: const Text('New Classroom Section'),
          content: SizedBox(
            width: dialogCtx.isMobile ? double.maxFinite : 440,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // First column — the section name.
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'e.g. Grade 1A', labelText: 'Class Name'),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 16),
                // Second column — the shift this section belongs to.
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedShift,
                    decoration: const InputDecoration(labelText: 'Shift'),
                    items: const [
                      DropdownMenuItem(value: 'Shift-1', child: Text('Shift-1')),
                      DropdownMenuItem(value: 'Shift-2', child: Text('Shift-2')),
                    ],
                    onChanged: (value) => setLocalState(() => selectedShift = value ?? 'Shift-1'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await ref.read(classroomControllerProvider.notifier).addClassroom(nameController.text.trim(), shift: selectedShift);
      } catch (e) {
        if (context.mounted) {
          String errMsg = e.toString();
          if (e is DioException) {
            final responseData = e.response?.data;
            if (responseData is Map && responseData['message'] != null) {
              errMsg = responseData['message'].toString();
            }
          }
          if (errMsg.contains('duplicate key error') || errMsg.contains('E11000')) {
            errMsg = 'Classroom with this name already exists';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
        }
      }
    }
  }
}
