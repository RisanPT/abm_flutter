import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_widgets.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/students/presentation/student_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_subjects_dialog.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_grid_screen.dart';
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
                error: (e, _) => Center(child: Text('Error loading students: $e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading classrooms: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context, ref),
        label: const Text('Add Classroom'),
        icon: const Icon(LucideIcons.plus),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
    );
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
          onViewStudents: () => context.push(RouteNames.students, extra: classroom.name),
          onManageSubjects: () => showDialog(
            context: context,
            builder: (context) => ClassroomSubjectsDialog(classroom: classroom),
          ),
          onManageTimetable: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimetableGridScreen(classroom: classroom),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddClassDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Classroom Section'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'e.g. Grade 1A', labelText: 'Class Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref.read(classroomControllerProvider.notifier).addClassroom(nameController.text.trim());
    }
  }
}
