import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/class_sort.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';

import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/students/presentation/student_controller.dart';
import 'package:dio/dio.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_subjects_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';

class ClassroomManagementScreen extends ConsumerStatefulWidget {
  const ClassroomManagementScreen({super.key});

  @override
  ConsumerState<ClassroomManagementScreen> createState() => _ClassroomManagementScreenState();
}

class _ClassroomManagementScreenState extends ConsumerState<ClassroomManagementScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final colors = context.colors;
    final classroomsAsync = ref.watch(classroomControllerProvider);
    final studentsAsync = ref.watch(allStudentsProvider);
    
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
            height: context.isMobile ? 190 : 172,
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
                data: (students) => _buildGrid(context, ref, classrooms, students, canEditAdmin),
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
                ref.invalidate(allStudentsProvider);
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

  Widget _buildGrid(BuildContext context, WidgetRef ref, List<ClassroomModel> classrooms, List<StudentModel> students, bool canEdit) {
    // Register order: pre-primary (incl. UKG) first, then numbered standards.
    final sorted = sortByClassName<ClassroomModel>(classrooms, (c) => c.name);

    if (sorted.isEmpty) {
      return AbmEmptyState(
        icon: LucideIcons.layers,
        title: 'No classrooms yet',
        message: canEdit
            ? 'Tap "Add Classroom" to create your first section.'
            : 'Classrooms will appear here once they are added.',
      );
    }

    // Counts for the summary strip.
    final counts = {for (final c in sorted) c.name: students.where((s) => s.classroom == c.name).length};
    final totalStudents = counts.values.fold<int>(0, (a, b) => a + b);
    final avg = sorted.isEmpty ? 0 : (totalStudents / sorted.length).round();

    // One visible scrollbar over the whole page; compact, fixed-height cards in a
    // responsive grid so the list stays short and scrolls cleanly on web.
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: _SummaryStrip(
                classrooms: sorted.length,
                students: totalStudents,
                avgPerClass: avg,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 186,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final classroom = sorted[index];
                  final count = counts[classroom.name] ?? 0;
                  return ClassroomCard(
                    title: classroom.name,
                    studentCount: count,
                    shift: classroom.shift,
                    onViewStudents: () => context.push(RouteNames.students, extra: classroom.name),
                    onEdit: canEdit ? () => _showRenameDialog(context, ref, classroom) : null,
                    onDelete: canEdit ? () => _confirmDelete(context, ref, classroom, count) : null,
                    onManageSubjects: canEdit
                        ? () => showDialog(
                              context: context,
                              builder: (context) => ClassroomSubjectsDialog(classroom: classroom),
                            )
                        : null,
                    onManageTimetable: () => context.push(RouteNames.timetable),
                  );
                },
                childCount: sorted.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, ClassroomModel classroom) async {
    final ctrl = TextEditingController(text: classroom.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Rename Class'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Class Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Save')),
        ],
      ),
    );
    final newName = ctrl.text.trim();
    if (ok == true && newName.isNotEmpty && newName != classroom.name) {
      try {
        await ref.read(classroomControllerProvider.notifier).renameClassroom(classroom.id, newName);
        ref.invalidate(allStudentsProvider); // enrolled students were re-pointed
        ref.invalidate(studentControllerProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class renamed.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
        }
      }
    }
    ctrl.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ClassroomModel classroom, int count) async {
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cannot delete "${classroom.name}" — $count student(s) are still enrolled. Move or remove them first.'),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete "${classroom.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(classroomControllerProvider.notifier).deleteClassroom(classroom.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class deleted.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
        }
      }
    }
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
          String errMsg = friendlyErrorMessage(e);
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
    nameController.dispose();
  }
}

/// A compact at-a-glance strip above the classroom grid.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.classrooms, required this.students, required this.avgPerClass});
  final int classrooms;
  final int students;
  final int avgPerClass;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget cell(IconData icon, String value, String label, Color tint) => Expanded(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 19, color: tint),
              ),
              const Gap(10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value,
                        style: context.typography.h4.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(label,
                        style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          cell(LucideIcons.layers, '$classrooms', 'Classrooms', colors.primary),
          _divider(colors.border),
          cell(LucideIcons.users, '$students', 'Students', colors.secondary),
          _divider(colors.border),
          cell(LucideIcons.gauge, '$avgPerClass', 'Avg / class', colors.green),
        ],
      ),
    );
  }

  Widget _divider(Color c) => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 12), color: c);
}
