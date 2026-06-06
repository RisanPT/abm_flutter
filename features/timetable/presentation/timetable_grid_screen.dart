import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_subjects_dialog.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/timetable/domain/class_timetable_model.dart';
import 'package:abm_madrasa/features/timetable/presentation/class_timetable_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _days = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

class TimetableGridScreen extends ConsumerStatefulWidget {
  const TimetableGridScreen({super.key, required this.classroom});
  final ClassroomModel classroom;

  @override
  ConsumerState<TimetableGridScreen> createState() => _TimetableGridScreenState();
}

class _TimetableGridScreenState extends ConsumerState<TimetableGridScreen> {
  final Map<String, Map<int, ClassTimetableEntry>> _gridData = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    for (final day in _days) {
      _gridData[day] = {};
      for (int i = 1; i <= 7; i++) {
        _gridData[day]![i] = ClassTimetableEntry(
          day: day,
          period: i,
          subjectName: '',
          teacherId: '',
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final schedule = _gridData.values
        .expand((m) => m.values)
        .where((e) => e.subjectName.isNotEmpty || e.teacherId.isNotEmpty)
        .map((e) => e.copyWith(teacherId: e.teacherId.isEmpty ? '' : e.teacherId)) // Backend handles '' now
        .toList();

    try {
      await ref
          .read(classTimetableControllerProvider(widget.classroom.name).notifier)
          .updateTimetable(schedule);
      ref.invalidate(timetableDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSubjectDefinitions() {
    showDialog(
      context: context,
      builder: (context) => ClassroomSubjectsDialog(classroom: widget.classroom),
    ).then((_) {
      // Refresh classroom data to get new subjects
      ref.invalidate(classroomControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(classTimetableControllerProvider(widget.classroom.name));
    final globalTimetableAsync = ref.watch(timetableDataProvider);
    final classroomsAsync = ref.watch(classroomControllerProvider);

    // Get updated classroom for subjects
    final currentClassroom = classroomsAsync.asData?.value.firstWhere(
      (c) => c.name == widget.classroom.name,
      orElse: () => widget.classroom,
    );
    final subjects = currentClassroom?.subjects ?? [];

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Manage Timetable',
            subtitle: 'Assign teachers and subjects for ${widget.classroom.name}',
            actions: [
              TextButton.icon(
                onPressed: _showSubjectDefinitions,
                icon: const Icon(LucideIcons.listTodo, color: Colors.white),
                label: const Text('Define Subjects', style: TextStyle(color: Colors.white)),
              ),
              const Gap(12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(LucideIcons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Schedule'),
              ),
            ],
          ),
          Expanded(
            child: timetableAsync.when(
              data: (timetable) {
                // Merge fetched data into grid
                for (final entry in timetable.schedule) {
                  _gridData[entry.day]?[entry.period] = entry;
                }

                return globalTimetableAsync.when(
                  data: (globalData) => _buildGrid(context, globalData.teachers, subjects),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List teachers, List<String> subjects) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Row (Days)
            Row(
              children: [
                const SizedBox(width: 60), // Period column spacer
                ..._days.map((day) => Container(
                      width: 180,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Text(day, style: context.typography.h4),
                    )),
              ],
            ),
            const Gap(12),
            // Period Rows
            ...List.generate(7, (pIndex) {
              final periodNumber = pIndex + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('P$periodNumber', style: context.typography.h4),
                    ),
                    ..._days.map((day) => _buildCell(day, periodNumber, teachers, subjects)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String day, int period, List teachers, List<String> subjects) {
    final entry = _gridData[day]![period]!;

    return Container(
      width: 180,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          // Subject Selection
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Subject', style: TextStyle(fontSize: 12)),
                value: subjects.contains(entry.subjectName) ? entry.subjectName : null,
                items: subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _gridData[day]![period] = entry.copyWith(subjectName: val ?? '');
                  });
                },
              ),
            ),
          ),
          const Divider(height: 8),
          // Teacher Selection
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Teacher', style: TextStyle(fontSize: 12)),
                value: teachers.any((t) => t.id == entry.teacherId) ? entry.teacherId : null,
                items: teachers
                    .map<DropdownMenuItem<String>>((t) => DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.fullName, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _gridData[day]![period] = entry.copyWith(teacherId: val ?? '');
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
