import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/planning_models.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _maroon = Color(0xFF5A2A2A);

/// Multi-row "Add Class" form: choose Date · Shift · Class, then add one or more
/// period rows (Subject · Teacher · Time). Picking a teacher fills in the subject
/// that teacher is assigned to.
Future<void> showAddClassSheet(
  BuildContext context, {
  required String instituteId,
  DateTime? initialDate,
  String initialShift = 'Shift-1',
  required VoidCallback onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => AddClassSheet(
      instituteId: instituteId,
      initialDate: initialDate ?? instituteToday(),
      initialShift: initialShift,
      onSaved: onSaved,
    ),
  );
}

class _ClassRow {
  String? subjectName;
  String? teacherId;
  final start = TextEditingController();
  final end = TextEditingController();
  void dispose() {
    start.dispose();
    end.dispose();
  }
}

class AddClassSheet extends ConsumerStatefulWidget {
  const AddClassSheet({
    super.key,
    required this.instituteId,
    required this.initialDate,
    required this.initialShift,
    required this.onSaved,
  });

  final String instituteId;
  final DateTime initialDate;
  final String initialShift;
  final VoidCallback onSaved;

  @override
  ConsumerState<AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends ConsumerState<AddClassSheet> {
  late DateTime _date = widget.initialDate;
  late String _shift = widget.initialShift;
  String? _class;
  final List<_ClassRow> _rows = [_ClassRow()];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<ClassroomOption> _classrooms = const [];
  List<TeacherOption> _teachers = const [];

  DateTime get _utcDate => DateTime.utc(_date.year, _date.month, _date.day);
  String _academicYear(DateTime d) => d.month >= 6 ? '${d.year}-${d.year + 1}' : '${d.year - 1}-${d.year}';

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(plannerRepositoryProvider).getDayTimetable(
            date: _utcDate, instituteId: widget.instituteId, academicYear: _academicYear(_date), shift: _shift,
          );
      _classrooms = data.classrooms;
      _teachers = data.teachers;
      _class ??= _classrooms.isNotEmpty ? _classrooms.first.name : null;
    } catch (e) {
      _error = describeApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _subjects {
    final c = _classrooms.firstWhere((c) => c.name == _class, orElse: () => const ClassroomOption());
    return c.subjects;
  }

  // Subject options for a row = the classroom's subjects PLUS the selected
  // teacher's subject (so the teacher's subject is always available/selectable).
  List<String> _subjectsFor(_ClassRow row) {
    final set = <String>{..._subjects};
    final t = _teacherById(row.teacherId);
    if (t != null && t.primarySubject.isNotEmpty) set.add(t.primarySubject);
    return set.toList();
  }

  TeacherOption? _teacherById(String? id) {
    for (final t in _teachers) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _save() async {
    final rows = _rows.where((r) => r.subjectName != null && r.teacherId != null).toList();
    if (_class == null || rows.isEmpty) {
      setState(() => _error = 'Add at least one row with a subject and a teacher.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(plannerRepositoryProvider);
    int added = 0;
    String? failMsg;
    // Add rows one by one (each auto-gets the next period number).
    for (final r in rows) {
      try {
        await repo.addClass(
          date: _utcDate,
          shift: _shift,
          classroomName: _class!,
          subjectName: r.subjectName!,
          teacherId: r.teacherId!,
          startTime: r.start.text.trim(),
          endTime: r.end.text.trim(),
          academicYear: _academicYear(_date),
          instituteId: widget.instituteId,
        );
        added += 1;
      } catch (e) {
        failMsg = describeApiError(e);
        break;
      }
    }

    if (added > 0) widget.onSaved();
    if (!mounted) return;
    if (failMsg == null) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('Added $added class(es) to $_shift'), backgroundColor: const Color(0xFF2F855A)));
    } else {
      setState(() {
        _saving = false;
        _error = added > 0 ? 'Added $added, then failed: $failMsg' : failMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.plusCircle, color: _maroon),
                  const Gap(10),
                  Expanded(child: Text('Add Classes', style: typography.bodyLargeSemiBold.copyWith(color: _maroon))),
                  IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_loading)
              const Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())
            else
              Flexible(child: _body(colors, typography)),
            if (!_loading) _footer(colors),
          ],
        ),
      ),
    );
  }

  Widget _body(ColorExtension colors, TypographyExtension typography) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: typography.bodySmall.copyWith(color: colors.red)),
            ),
          // Date · Shift
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.calendar, size: 16),
                  label: Text(DateFormat('dd MMM yyyy').format(_date)),
                  style: OutlinedButton.styleFrom(foregroundColor: _maroon, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ),
              const Gap(12),
              Container(
                decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [_shiftTab('Shift-1'), _shiftTab('Shift-2')]),
              ),
            ],
          ),
          const Gap(14),
          _label('Class', typography, colors),
          DropdownButtonFormField<String>(
            initialValue: _classrooms.any((c) => c.name == _class) ? _class : null,
            isExpanded: true,
            decoration: _dec(colors),
            items: _classrooms.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() {
              _class = v;
              for (final r in _rows) {
                r.subjectName = null; // subjects depend on class
              }
            }),
          ),
          const Gap(18),
          Text('Periods', style: typography.bodyMediumSemiBold.copyWith(color: _maroon)),
          const Gap(8),
          for (int i = 0; i < _rows.length; i++) _rowCard(i, colors, typography),
          const Gap(4),
          TextButton.icon(
            onPressed: () => setState(() => _rows.add(_ClassRow())),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add another period'),
            style: TextButton.styleFrom(foregroundColor: _maroon),
          ),
        ],
      ),
    );
  }

  Widget _rowCard(int i, ColorExtension colors, TypographyExtension typography) {
    final row = _rows[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.border)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 13, backgroundColor: _maroon.withValues(alpha: 0.1), child: Text('${i + 1}', style: typography.bodySmallSemiBold.copyWith(color: _maroon))),
              const Gap(10),
              Text('Period ${i + 1}', style: typography.bodyMediumSemiBold.copyWith(color: _maroon)),
              const Spacer(),
              if (_rows.length > 1)
                IconButton(
                  icon: Icon(LucideIcons.trash2, size: 18, color: colors.red),
                  onPressed: () => setState(() {
                    _rows[i].dispose();
                    _rows.removeAt(i);
                  }),
                ),
            ],
          ),
          const Gap(6),
          // Teacher first — choosing a teacher fills in their subject.
          DropdownButtonFormField<String>(
            key: ValueKey('teacher-$_class-$i'),
            initialValue: _teachers.any((t) => t.id == row.teacherId) ? row.teacherId : null,
            isExpanded: true,
            decoration: _dec(colors, hint: 'Teacher'),
            items: _teachers.map((t) {
              final subj = t.primarySubject;
              return DropdownMenuItem(value: t.id, child: Text(subj.isNotEmpty ? '${t.fullName}  —  $subj' : t.fullName, overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) => setState(() {
              row.teacherId = v;
              // Auto-fill the subject with the teacher's own subject (Specialty).
              final t = _teacherById(v);
              if (t != null && t.primarySubject.isNotEmpty) row.subjectName = t.primarySubject;
            }),
          ),
          const Gap(8),
          Builder(builder: (_) {
            final subjectItems = _subjectsFor(row);
            return DropdownButtonFormField<String>(
              key: ValueKey('subject-$_class-$i-${row.teacherId}-${row.subjectName}'),
              initialValue: subjectItems.contains(row.subjectName) ? row.subjectName : null,
              isExpanded: true,
              decoration: _dec(colors, hint: 'Subject'),
              items: subjectItems.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => row.subjectName = v),
            );
          }),
          const Gap(8),
          Row(
            children: [
              Expanded(child: _timeField(row.start, 'Start', colors)),
              const Gap(10),
              Expanded(child: _timeField(row.end, 'End', colors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(ColorExtension colors) {
    final count = _rows.where((r) => r.subjectName != null && r.teacherId != null).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saving || count == 0 ? null : _save,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.check, size: 18),
          label: Text(count == 0 ? 'Add to $_shift' : 'Add $count class(es) to $_shift'),
          style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
    );
  }

  // Tap-to-pick time field (opens a clock) that writes 24h "HH:mm".
  Widget _timeField(TextEditingController controller, String label, ColorExtension colors) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: _dec(colors, hint: label).copyWith(
        prefixIcon: const Icon(LucideIcons.clock, size: 16, color: _maroon),
      ),
      onTap: () => _pickTime(controller),
    );
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(controller.text) ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  TimeOfDay? _parseTime(String v) {
    final parts = v.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Widget _label(String text, TypographyExtension t, ColorExtension c) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: t.bodySmallSemiBold.copyWith(color: c.textSecondary)));

  InputDecoration _dec(ColorExtension colors, {String? hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
      );

  Widget _shiftTab(String shift) {
    final selected = _shift == shift;
    return InkWell(
      onTap: () => setState(() => _shift = shift),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _maroon.withValues(alpha: 0.1) : Colors.transparent,
          border: shift == 'Shift-1' ? Border(right: BorderSide(color: context.colors.border)) : null,
        ),
        child: Text(shift, style: context.typography.bodySmallSemiBold.copyWith(color: selected ? _maroon : context.colors.textSecondary)),
      ),
    );
  }
}
