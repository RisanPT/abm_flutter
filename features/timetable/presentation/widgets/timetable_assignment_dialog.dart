import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/timetable/data/timetable_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/class_timetable_model.dart';
import 'package:abm_madrasa/features/timetable/domain/timetable_model.dart';
import 'package:abm_madrasa/features/timetable/presentation/class_timetable_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/shift_planner_controller.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_subjects_dialog.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// Dialog for the Head Master to plan the timetable for a specific month.
/// Date selection is restricted to the ShiftPlan's class dates only.
class TimetableAssignmentDialog extends ConsumerStatefulWidget {
  const TimetableAssignmentDialog({
    super.key,
    required this.data,
    required this.shift,
    required this.year,
    required this.month,
    required this.academicYear,
    this.initialClassName,
  });

  final TimetableData data;
  final String shift;
  final int year;
  final int month;
  final String academicYear;
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

  /// ShiftPlan class dates loaded for this shift + month.
  List<DateTime> _shiftPlanDates = [];
  bool _isLoadingShiftPlan = true;

  @override
  void initState() {
    super.initState();
    _selectedClassName = widget.initialClassName ??
        (widget.data.allClassrooms.isNotEmpty
            ? widget.data.allClassrooms.first.name
            : null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadShiftPlanDates();
      if (_selectedClassName != null) {
        await _loadClassSchedule(_selectedClassName!);
      }
    });
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  /// Load the allowed class dates from the ShiftPlan for this month.
  Future<void> _loadShiftPlanDates() async {
    setState(() => _isLoadingShiftPlan = true);
    try {
      final dates = await ref.read(
        shiftPlannerControllerProvider(
          widget.academicYear,
          widget.shift,
          widget.year,
          widget.month,
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _shiftPlanDates = dates.map((d) => DateTime.utc(d.year, d.month, d.day)).toList()
          ..sort();
        _isLoadingShiftPlan = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingShiftPlan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classroomsAsync = ref.watch(classroomControllerProvider);
    final classrooms = classroomsAsync.asData?.value ?? widget.data.allClassrooms;
    final selectedClassroom = _resolveSelectedClassroom(classrooms);
    final subjects = selectedClassroom?.subjects ?? const <String>[];

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 880),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan Timetable', style: context.typography.h3),
                        const Gap(4),
                        Text(
                          '${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))} '
                          '• ${widget.academicYear} • ${widget.shift}',
                          style: context.typography.bodyMedium.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const Gap(8),
              // ── ShiftPlan dates summary ───────────────────────────────────
              _isLoadingShiftPlan
                  ? const LinearProgressIndicator()
                  : _shiftPlanDates.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.alertCircle,
                                  color: Colors.orange, size: 18),
                              const Gap(10),
                              Expanded(
                                child: Text(
                                  'No Shift Plan found for ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))} '
                                  '(${widget.shift}). Save a Shift Plan first before planning the timetable.',
                                  style: context.typography.bodySmall.copyWith(
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: context.colors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.calendarCheck,
                                  color: context.colors.primary, size: 16),
                              const Gap(8),
                              Text(
                                'Shift Plan: ${_shiftPlanDates.length} class date${_shiftPlanDates.length == 1 ? '' : 's'} available for scheduling',
                                style: context.typography.bodySmall.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Wrap(
                                spacing: 4,
                                children: _shiftPlanDates
                                    .take(6)
                                    .map((d) => Chip(
                                          label: Text(DateFormat('MMM d').format(d),
                                              style: const TextStyle(fontSize: 11)),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: context.colors.primary
                                              .withValues(alpha: 0.1),
                                        ))
                                    .toList(),
                              ),
                              if (_shiftPlanDates.length > 6)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text('+${_shiftPlanDates.length - 6} more',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: context.colors.textSecondary)),
                                ),
                            ],
                          ),
                        ),
              const Gap(16),
              // ── Class selector ───────────────────────────────────────────
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
              if (selectedClassroom != null && subjects.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final subject in subjects) _SubjectChip(label: subject),
                  ],
                ),
              const Gap(20),
              if (_selectedClassName != null && _shiftPlanDates.isNotEmpty) ...[
                Row(
                  children: [
                    Text('Timetable Periods', style: context.typography.h4),
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
                                    : 'No periods yet. Tap "Add Period" to schedule a class.',
                                style: context.typography.bodyMedium.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _drafts.length,
                              itemBuilder: (context, index) => _PeriodEditor(
                                key: ValueKey('${_drafts[index].date.toIso8601String()}-$index'),
                                draft: _drafts[index],
                                teachers: widget.data.teachers,
                                subjects: subjects,
                                shiftPlanDates: _shiftPlanDates,
                                canRemove: true,
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
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAssignments,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.save, size: 16),
                      label: Text(_isSaving ? 'Saving...' : 'Publish Timetable'),
                    ),
                  ],
                ),
              ] else if (_shiftPlanDates.isEmpty && !_isLoadingShiftPlan)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Create a Shift Plan for this month before planning the timetable.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_selectedClassName == null)
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
        labelText: 'Classroom',
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
    if (_selectedClassName != null) {
      await _loadClassSchedule(_selectedClassName!);
    }
  }

  Future<void> _loadClassSchedule(String className) async {
    setState(() => _isLoadingSchedule = true);
    try {
      final instituteId = ref.read(selectedInstituteProvider).id;
      final timetable = await ref.read(timetableRepositoryProvider).getClassroomTimetable(
            className,
            instituteId,
            widget.shift,
            year: widget.year,
            month: widget.month,
            academicYear: widget.academicYear,
          );
      final drafts = timetable.schedule.isEmpty
          ? [
              _PeriodDraft(
                date: _shiftPlanDates.isNotEmpty ? _shiftPlanDates.first : DateTime.utc(widget.year, widget.month, 1),
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
    final defaultDate = _shiftPlanDates.isNotEmpty
        ? _shiftPlanDates.first
        : DateTime.utc(widget.year, widget.month, 1);
    setState(() {
      _drafts.add(
        _PeriodDraft(
          date: defaultDate,
          period: (_drafts.length + 1).clamp(1, 7),
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
      final instituteId = ref.read(selectedInstituteProvider).id;
      await ref.read(timetableRepositoryProvider).updateClassroomTimetable(
            _selectedClassName!,
            instituteId,
            widget.shift,
            widget.academicYear,
            widget.year,
            widget.month,
            schedule,
          );

      // Invalidate providers after save
      final args = (
        shift: widget.shift,
        year: widget.year,
        month: widget.month,
        academicYear: widget.academicYear,
      );
      ref.invalidate(timetableDataProvider(args));
      ref.invalidate(scheduledDatesProvider(args));
      ref.invalidate(classTimetableControllerProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable published successfully ✓')),
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

// ─── Period Draft (data holder) ──────────────────────────────────────────────

class _PeriodDraft {
  _PeriodDraft({
    required this.date,
    required this.period,
    required this.teacherId,
    required this.subjectName,
    required String startTime,
    required String endTime,
  })  : startTimeController = TextEditingController(text: startTime),
        endTimeController = TextEditingController(text: endTime);

  DateTime date;
  int period;
  String teacherId;
  String subjectName;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;

  factory _PeriodDraft.fromModel(ClassTimetableEntry entry) => _PeriodDraft(
        date: DateTime.utc(entry.date.year, entry.date.month, entry.date.day),
        period: entry.period,
        teacherId: entry.teacherId,
        subjectName: entry.subjectName,
        startTime: entry.startTime,
        endTime: entry.endTime,
      );

  ClassTimetableEntry toModel() => ClassTimetableEntry(
        date: date,
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

// ─── Period Editor ───────────────────────────────────────────────────────────

class _PeriodEditor extends StatefulWidget {
  const _PeriodEditor({
    super.key,
    required this.draft,
    required this.teachers,
    required this.subjects,
    required this.shiftPlanDates,
    required this.canRemove,
    required this.onRemove,
  });

  final _PeriodDraft draft;
  final List<TimetableTeacherSummary> teachers;
  final List<String> subjects;
  final List<DateTime> shiftPlanDates; // Only dates allowed by ShiftPlan
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_PeriodEditor> createState() => _PeriodEditorState();
}

class _PeriodEditorState extends State<_PeriodEditor> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final subjects = widget.subjects;
    final teachers = widget.teachers;
    final shiftPlanDates = widget.shiftPlanDates;

    // Ensure draft.date is one of the allowed ShiftPlan dates
    final normalizedDraftDate = DateTime.utc(draft.date.year, draft.date.month, draft.date.day);
    final isDateValid = shiftPlanDates.any((d) =>
        d.year == normalizedDraftDate.year &&
        d.month == normalizedDraftDate.month &&
        d.day == normalizedDraftDate.day);

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
          fullName: 'Unknown Teacher',
          title: '',
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDateValid
              ? context.colors.border.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Period ${draft.period} — ${DateFormat('EEE, MMM d').format(draft.date)}',
                style: context.typography.bodyMediumSemiBold,
              ),
              if (widget.canRemove)
                InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(LucideIcons.trash2,
                        color: Colors.redAccent.withValues(alpha: 0.8), size: 18),
                  ),
                ),
            ],
          ),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Date + Period ───────────────────────────────────
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Date — restricted to ShiftPlan dates only
                    DropdownButtonFormField<DateTime>(
                      value: isDateValid ? normalizedDraftDate : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Class Date',
                        filled: true,
                        errorText: isDateValid ? null : 'Not in Shift Plan',
                      ),
                      items: shiftPlanDates.map((date) {
                        return DropdownMenuItem<DateTime>(
                          value: date,
                          child: Text(DateFormat('EEE, MMM d yyyy').format(date)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => draft.date = value);
                        }
                      },
                    ),
                    const Gap(16),
                    DropdownButtonFormField<int>(
                      value: draft.period,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        filled: true,
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
                          setState(() => draft.period = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Gap(16),
              // ── Right: Times + Subject + Teacher ─────────────────────
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
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
                      ],
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: draft.subjectName.isEmpty ? null : draft.subjectName,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              filled: true,
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
                              setState(() => draft.subjectName = value ?? '');
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: draft.teacherId.isEmpty ? null : draft.teacherId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Teacher',
                              filled: true,
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
                              setState(() => draft.teacherId = value ?? '');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Subject Chip ────────────────────────────────────────────────────────────

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
