import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/timetable/data/timetable_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/class_timetable_model.dart';
import 'package:abm_madrasa/features/timetable/domain/timetable_model.dart';
import 'package:abm_madrasa/features/timetable/presentation/class_timetable_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_controller.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_subjects_dialog.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _days = <String>[
  'Saturday',
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
];

class TimetableAssignmentDialog extends ConsumerStatefulWidget {
  const TimetableAssignmentDialog({
    super.key,
    required this.data,
    this.initialClassName,
  });

  final TimetableData data;
  final String? initialClassName;

  @override
  ConsumerState<TimetableAssignmentDialog> createState() =>
      _TimetableAssignmentDialogState();
}

class _TimetableAssignmentDialogState
    extends ConsumerState<TimetableAssignmentDialog> {
  String? _selectedClassName;
  List<_PeriodDraft> _drafts = [];
  bool _isLoadingSchedule = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedClassName = widget.initialClassName ??
        (widget.data.allClassrooms.isNotEmpty
            ? widget.data.allClassrooms.first.name
            : null);
    if (_selectedClassName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadClassSchedule(_selectedClassName!);
      });
    }
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classroomsAsync = ref.watch(classroomControllerProvider);
    final classrooms =
        classroomsAsync.asData?.value ?? widget.data.allClassrooms;
    final selectedClassroom = _resolveSelectedClassroom(classrooms);
    final subjects = selectedClassroom?.subjects ?? const <String>[];

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 840),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Manage Timetable Assignments',
                        style: context.typography.h3),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const Gap(8),
              Text(
                'Subjects are defined per class, then assigned to teachers by day and period.',
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const Gap(18),
              Row(
                children: [
                  Expanded(child: _buildClassDropdown(classrooms)),
                  const Gap(12),
                  OutlinedButton.icon(
                    onPressed: selectedClassroom == null
                        ? null
                        : () => _showSubjectsDialog(selectedClassroom),
                    icon: const Icon(LucideIcons.plusCircle, size: 18),
                    label: const Text('Add Subject'),
                  ),
                ],
              ),
              const Gap(12),
              if (selectedClassroom != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final subject in subjects) _SubjectChip(label: subject),
                  ],
                ),
              const Gap(20),
              if (_selectedClassName != null) ...[
                Row(
                  children: [
                    Text('Periods', style: context.typography.h4),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _addPeriod(subjects),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Add Period'),
                    ),
                  ],
                ),
                const Gap(12),
                Expanded(
                  child: _isLoadingSchedule
                      ? const Center(child: CircularProgressIndicator())
                      : _drafts.isEmpty
                          ? Center(
                              child: Text(
                                subjects.isEmpty
                                    ? 'Add subjects first, then create timetable periods.'
                                    : 'No timetable periods created yet.',
                                style: context.typography.bodyMedium.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _drafts.length,
                              itemBuilder: (context, index) => _PeriodEditor(
                                key: ValueKey('${_drafts[index].day}-$index'),
                                draft: _drafts[index],
                                teachers: widget.data.teachers,
                                subjects: subjects,
                                canRemove: _drafts.length > 1,
                                onRemove: () => _removePeriod(index),
                              ),
                            ),
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Gap(12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveAssignments,
                      child: Text(_isSaving ? 'Saving...' : 'Save Assignments'),
                    ),
                  ],
                ),
              ] else
                const Expanded(
                  child: Center(
                    child: Text('No classes available. Create a class first.'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ClassroomModel? _resolveSelectedClassroom(List<ClassroomModel> classrooms) {
    if (classrooms.isEmpty) return null;
    final matched = classrooms.where((c) => c.name == _selectedClassName);
    if (matched.isNotEmpty) return matched.first;
    _selectedClassName = classrooms.first.name;
    return classrooms.first;
  }

  Widget _buildClassDropdown(List<ClassroomModel> classrooms) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedClassName,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Class',
        border: OutlineInputBorder(),
      ),
      items: classrooms
          .map(
            (classroom) => DropdownMenuItem(
              value: classroom.name,
              child: Text(classroom.name),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedClassName = value);
          _loadClassSchedule(value);
        }
      },
    );
  }

  Future<void> _showSubjectsDialog(ClassroomModel classroom) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ClassroomSubjectsDialog(classroom: classroom),
    );
    ref.invalidate(classroomControllerProvider);
    ref.invalidate(timetableDataProvider);
    if (_selectedClassName != null) {
      await _loadClassSchedule(_selectedClassName!);
    }
  }

  Future<void> _loadClassSchedule(String className) async {
    setState(() => _isLoadingSchedule = true);
    try {
      final timetable = await ref.read(timetableRepositoryProvider).getClassroomTimetable(className);
      final drafts = timetable.schedule.isEmpty
          ? [
              _PeriodDraft(
                day: _days.first,
                period: 1,
                teacherId: '',
                subjectName: '',
                startTime: '08:00',
                endTime: '09:30',
              ),
            ]
          : timetable.schedule.map(_PeriodDraft.fromModel).toList();

      for (final draft in _drafts) {
        draft.dispose();
      }
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _isLoadingSchedule = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSchedule = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _addPeriod(List<String> subjects) {
    setState(() {
      _drafts.add(
        _PeriodDraft(
          day: _days.first,
          period: _drafts.length + 1 > 7 ? 7 : _drafts.length + 1,
          teacherId: '',
          subjectName: subjects.isNotEmpty ? subjects.first : '',
          startTime: '08:00',
          endTime: '09:30',
        ),
      );
    });
  }

  void _removePeriod(int index) {
    setState(() {
      _drafts[index].dispose();
      _drafts.removeAt(index);
    });
  }

  Future<void> _saveAssignments() async {
    if (_selectedClassName == null) return;

    final schedule = _drafts.map((draft) => draft.toModel()).toList();
    if (schedule.any((entry) => entry.subjectName.isEmpty || entry.teacherId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each period must have both a subject and a teacher')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(timetableRepositoryProvider).updateClassroomTimetable(
            _selectedClassName!,
            schedule,
          );
      ref.invalidate(timetableDataProvider);
      ref.invalidate(classTimetableControllerProvider(_selectedClassName!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignments updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PeriodDraft {
  _PeriodDraft({
    required this.day,
    required this.period,
    required this.teacherId,
    required this.subjectName,
    required String startTime,
    required String endTime,
  })  : startTimeController = TextEditingController(text: startTime),
        endTimeController = TextEditingController(text: endTime);

  String day;
  int period;
  String teacherId;
  String subjectName;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;

  factory _PeriodDraft.fromModel(ClassTimetableEntry entry) => _PeriodDraft(
        day: entry.day,
        period: entry.period,
        teacherId: entry.teacherId,
        subjectName: entry.subjectName,
        startTime: entry.startTime,
        endTime: entry.endTime,
      );

  ClassTimetableEntry toModel() => ClassTimetableEntry(
        day: day,
        period: period,
        subjectName: subjectName,
        teacherId: teacherId,
        startTime: startTimeController.text.trim(),
        endTime: endTimeController.text.trim(),
      );

  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
  }
}

class _PeriodEditor extends StatelessWidget {
  const _PeriodEditor({
    super.key,
    required this.draft,
    required this.teachers,
    required this.subjects,
    required this.canRemove,
    required this.onRemove,
  });

  final _PeriodDraft draft;
  final List<TimetableTeacherSummary> teachers;
  final List<String> subjects;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subjectItems = [
      if (draft.subjectName.isNotEmpty && !subjects.contains(draft.subjectName))
        draft.subjectName,
      ...subjects,
    ];

    final hasDraftTeacher = draft.teacherId.isNotEmpty;
    final containsDraftTeacher = teachers.any((t) => t.id == draft.teacherId);
    final teacherItems = [
      ...teachers,
      if (hasDraftTeacher && !containsDraftTeacher)
        TimetableTeacherSummary(
          id: draft.teacherId,
          fullName: 'Unknown Teacher (${draft.teacherId})',
          title: '',
        ),
    ];

    final dayItems = [
      if (draft.day.isNotEmpty && !_days.contains(draft.day))
        draft.day,
      ..._days,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: draft.day,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                  ),
                  items: dayItems
                      .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      draft.day = value;
                    }
                  },
                ),
              ),
              const Gap(12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: draft.period,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('Period ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      draft.period = value;
                    }
                  },
                ),
              ),
              const Gap(12),
              Expanded(
                child: ABMTextField(
                  label: 'Start Time',
                  hint: '08:00',
                  controller: draft.startTimeController,
                ),
              ),
              const Gap(12),
              Expanded(
                child: ABMTextField(
                  label: 'End Time',
                  hint: '09:30',
                  controller: draft.endTimeController,
                ),
              ),
              if (canRemove) ...[
                const Gap(8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(LucideIcons.trash2, color: Colors.red),
                ),
              ],
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: draft.teacherId.isEmpty ? null : draft.teacherId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    border: OutlineInputBorder(),
                  ),
                  items: teacherItems
                      .map(
                        (teacher) => DropdownMenuItem(
                          value: teacher.id,
                          child: Text(teacher.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    draft.teacherId = value ?? '';
                  },
                ),
              ),
              const Gap(12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: draft.subjectName.isEmpty ? null : draft.subjectName,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: subjectItems
                      .map(
                        (subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    draft.subjectName = value ?? '';
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.typography.bodySmallSemiBold.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
