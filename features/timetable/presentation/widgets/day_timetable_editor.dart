import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/planning_models.dart';
import 'package:abm_madrasa/features/timetable/presentation/planner_status.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _maroon = Color(0xFF5A2A2A);

/// Opens the day timetable editor as a modal sheet.
Future<void> showDayTimetableEditor(
  BuildContext context, {
  required DateTime date,
  required String shift,
  required String academicYear,
  required String instituteId,
  required VoidCallback onChanged,
  required Future<void> Function() onMarkHoliday,
  required Future<void> Function() onCancelDay,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DayTimetableEditor(
      date: date,
      shift: shift,
      academicYear: academicYear,
      instituteId: instituteId,
      onChanged: onChanged,
      onMarkHoliday: onMarkHoliday,
      onCancelDay: onCancelDay,
    ),
  );
}

class _PeriodRow {
  _PeriodRow({
    required this.period,
    this.subjectName,
    this.teacherId,
    String startTime = '',
    String endTime = '',
    String room = '',
  })  : start = TextEditingController(text: startTime),
        end = TextEditingController(text: endTime),
        room = TextEditingController(text: room);

  int period;
  String? subjectName;
  String? teacherId;
  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController room;

  void dispose() {
    start.dispose();
    end.dispose();
    room.dispose();
  }
}

class DayTimetableEditor extends ConsumerStatefulWidget {
  const DayTimetableEditor({
    super.key,
    required this.date,
    required this.shift,
    required this.academicYear,
    required this.instituteId,
    required this.onChanged,
    required this.onMarkHoliday,
    required this.onCancelDay,
  });

  final DateTime date;
  final String shift;
  final String academicYear;
  final String instituteId;
  final VoidCallback onChanged;
  final Future<void> Function() onMarkHoliday;
  final Future<void> Function() onCancelDay;

  @override
  ConsumerState<DayTimetableEditor> createState() => _DayTimetableEditorState();
}

class _DayTimetableEditorState extends ConsumerState<DayTimetableEditor> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  DayTimetable? _data;
  String? _classroom;
  final List<_PeriodRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(plannerRepositoryProvider);
      final data = await repo.getDayTimetable(
        date: widget.date,
        instituteId: widget.instituteId,
        academicYear: widget.academicYear,
        shift: widget.shift,
      );
      _data = data;
      _classroom = data.classrooms.isNotEmpty ? data.classrooms.first.name : null;
      _rebuildRows();
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _rebuildRows() {
    for (final r in _rows) {
      r.dispose();
    }
    _rows.clear();
    final periods = (_data?.periods ?? []).where((p) => p.classroomName == _classroom).toList()
      ..sort((a, b) => a.period.compareTo(b.period));
    for (final p in periods) {
      _rows.add(_PeriodRow(
        period: p.period,
        subjectName: p.subjectName.isEmpty ? null : p.subjectName,
        teacherId: p.teacherId,
        startTime: p.startTime,
        endTime: p.endTime,
        room: p.room,
      ));
    }
    if (_rows.isEmpty) _addRow();
  }

  void _addRow() {
    final nextPeriod = _rows.isEmpty ? 1 : (_rows.map((r) => r.period).reduce((a, b) => a > b ? a : b) + 1);
    _rows.add(_PeriodRow(period: nextPeriod));
  }

  List<String> get _subjects {
    final c = _data?.classrooms.firstWhere(
      (c) => c.name == _classroom,
      orElse: () => const ClassroomOption(),
    );
    return c?.subjects ?? const [];
  }

  Future<void> _save({required bool publish}) async {
    final rows = _rows.where((r) => r.subjectName != null || r.teacherId != null).toList();
    for (final r in rows) {
      if (r.subjectName == null || r.teacherId == null) {
        setState(() => _error = 'Each configured period needs both a subject and a teacher.');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(plannerRepositoryProvider);
      final periods = rows
          .map((r) => DayPeriod(
                period: r.period,
                subjectName: r.subjectName ?? '',
                teacherId: r.teacherId,
                startTime: r.start.text.trim(),
                endTime: r.end.text.trim(),
                room: r.room.text.trim(),
              ))
          .toList();
      await repo.saveDayDraft(
        date: widget.date,
        instituteId: widget.instituteId,
        academicYear: widget.academicYear,
        shift: widget.shift,
        classroomName: _classroom!,
        periods: periods,
      );
      if (publish) {
        await repo.publishDay(
          date: widget.date,
          instituteId: widget.instituteId,
          academicYear: widget.academicYear,
          shift: widget.shift,
          classroomName: _classroom,
        );
      }
      widget.onChanged();
      if (mounted) {
        // Capture the messenger before popping — after pop this State is
        // unmounted and its context is defunct.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(
          content: Text(publish ? 'Timetable published' : 'Draft saved'),
          backgroundColor: const Color(0xFF2F855A),
        ));
      }
    } catch (e) {
      setState(() => _error = _extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _extractError(Object e) => describeApiError(e);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final style = plannerStatusStyle(_data?.dayStatus ?? 'Planned');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(colors, typography, style),
            const Divider(height: 1),
            if (_loading)
              const Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())
            else
              Flexible(child: _body(colors, typography)),
            if (!_loading) _footer(colors, typography),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorExtension colors, TypographyExtension typography, PlannerStatusStyle style) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: style.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(style.icon, color: style.color, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, dd MMMM yyyy').format(widget.date),
                    style: typography.bodyLargeSemiBold.copyWith(color: _maroon)),
                Text('${widget.shift}  •  ${style.label}',
                    style: typography.bodySmall.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical),
            onSelected: (v) async {
              if (v == 'holiday') {
                Navigator.of(context).pop();
                await widget.onMarkHoliday();
              } else if (v == 'cancel') {
                Navigator.of(context).pop();
                await widget.onCancelDay();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'holiday', child: Text('Mark as Holiday')),
              PopupMenuItem(value: 'cancel', child: Text('Cancel Day')),
            ],
          ),
          IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _body(ColorExtension colors, TypographyExtension typography) {
    final classrooms = _data?.classrooms ?? const [];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          Row(
            children: [
              Text('Classroom', style: typography.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
              const Gap(12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: classrooms.any((c) => c.name == _classroom) ? _classroom : null,
                  isExpanded: true,
                  decoration: _fieldDecoration(colors),
                  items: classrooms
                      .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _classroom = v;
                    _rebuildRows();
                  }),
                ),
              ),
            ],
          ),
          const Gap(20),
          for (int i = 0; i < _rows.length; i++) _periodCard(i, colors, typography),
          const Gap(8),
          TextButton.icon(
            onPressed: () => setState(_addRow),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Period'),
            style: TextButton.styleFrom(foregroundColor: _maroon),
          ),
        ],
      ),
    );
  }

  Widget _periodCard(int i, ColorExtension colors, TypographyExtension typography) {
    final row = _rows[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _maroon.withValues(alpha: 0.1),
                child: Text('${row.period}', style: typography.bodySmallSemiBold.copyWith(color: _maroon)),
              ),
              const Gap(10),
              Text('Period ${row.period}', style: typography.bodyMediumSemiBold.copyWith(color: _maroon)),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.trash2, size: 18, color: colors.red),
                onPressed: () => setState(() {
                  _rows[i].dispose();
                  _rows.removeAt(i);
                  if (_rows.isEmpty) _addRow();
                }),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  // Key by classroom so the field resets (instead of keeping a
                  // stale value not in the new items) when the classroom changes.
                  key: ValueKey('subject-$_classroom-${row.period}'),
                  initialValue: _subjects.contains(row.subjectName) ? row.subjectName : null,
                  isExpanded: true,
                  decoration: _fieldDecoration(colors, hint: 'Subject'),
                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => row.subjectName = v),
                ),
              ),
              const Gap(10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('teacher-$_classroom-${row.period}'),
                  initialValue: (_data?.teachers ?? []).any((t) => t.id == row.teacherId) ? row.teacherId : null,
                  isExpanded: true,
                  decoration: _fieldDecoration(colors, hint: 'Teacher'),
                  items: (_data?.teachers ?? [])
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => row.teacherId = v),
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(child: _timeField(row.start, 'Start', colors)),
              const Gap(10),
              Expanded(child: _timeField(row.end, 'End', colors)),
              const Gap(10),
              Expanded(child: TextField(controller: row.room, decoration: _fieldDecoration(colors, hint: 'Room'))),
            ],
          ),
        ],
      ),
    );
  }

  // Tap-to-pick time field (opens a clock) that writes 24h "HH:mm".
  Widget _timeField(TextEditingController controller, String label, ColorExtension colors) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: _fieldDecoration(colors, hint: label).copyWith(
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

  InputDecoration _fieldDecoration(ColorExtension colors, {String? hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
      );

  Widget _footer(ColorExtension colors, TypographyExtension typography) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving || _classroom == null ? null : () => _save(publish: false),
              icon: const Icon(LucideIcons.save, size: 18),
              label: const Text('Save Draft'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const Gap(12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saving || _classroom == null ? null : () => _save(publish: true),
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.checkCircle2, size: 18),
              label: const Text('Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F855A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
