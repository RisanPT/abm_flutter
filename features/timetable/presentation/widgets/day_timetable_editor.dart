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
    this.existed = false,
    String startTime = '',
    String endTime = '',
    String room = '',
  })  : start = TextEditingController(text: startTime),
        end = TextEditingController(text: endTime),
        room = TextEditingController(text: room);

  int period;
  String? subjectName;
  String? teacherId;
  bool existed; // true = already saved on the backend (can be deleted/cancelled)
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
        existed: true,
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

  void _removeRowLocal(int i) {
    setState(() {
      _rows[i].dispose();
      _rows.removeAt(i);
      if (_rows.isEmpty) _addRow();
    });
  }

  // Permanently delete an assigned class (backend hard delete; blocked if
  // attendance exists, in which case the office is told to cancel instead).
  Future<void> _deleteRow(int i) async {
    final row = _rows[i];
    if (!row.existed) { _removeRowLocal(i); return; } // never saved → just drop it

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this class?'),
        content: Text('Period ${row.period} will be permanently removed from this day. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(plannerRepositoryProvider).deleteClass(
            date: widget.date, instituteId: widget.instituteId, academicYear: widget.academicYear,
            shift: widget.shift, classroomName: _classroom ?? '', period: row.period,
          );
      if (!mounted) return;
      _removeRowLocal(i);
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class deleted'), backgroundColor: Color(0xFF16A34A)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      // Delete is blocked once attendance exists — offer to cancel instead.
      if (msg.toLowerCase().contains('cancel')) {
        final doCancel = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Already attended'),
            content: Text('$msg\n\nCancel this class instead? It stays on record but is marked cancelled.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel class')),
            ],
          ),
        );
        if (doCancel == true) await _cancelRow(i);
      } else {
        setState(() => _error = msg);
      }
    }
  }

  // Soft-cancel an assigned class (keeps the record; attendance disabled).
  Future<void> _cancelRow(int i) async {
    final row = _rows[i];
    if (!row.existed) { _removeRowLocal(i); return; }
    try {
      await ref.read(plannerRepositoryProvider).cancelClass(
            date: widget.date, instituteId: widget.instituteId, academicYear: widget.academicYear,
            shift: widget.shift, classroomName: _classroom ?? '', period: row.period,
          );
      if (!mounted) return;
      _removeRowLocal(i);
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class cancelled')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Replicate this day's timetable to future class days so it persists across
  // months without rebuilding (the recurring-schedule fix).
  Future<void> _copyForward() async {
    if (_classroom == null) {
      setState(() => _error = 'Select a classroom first.');
      return;
    }
    final weekday = DateFormat('EEEE').format(widget.date);
    bool sameWeekday = true;
    bool publish = true;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Copy timetable forward'),
          content: SizedBox(
            width: MediaQuery.sizeOf(ctx).width * 0.9 < 360 ? MediaQuery.sizeOf(ctx).width * 0.9 : 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copy $_classroom’s timetable from this day to future class days for the rest of the term. Days that already have a timetable are kept.',
                  style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary),
                ),
                const Gap(4),
                Text('Tip: Save or Publish this day first so your latest changes are copied.',
                    style: context.typography.bodySmall.copyWith(color: _maroon)),
                const Gap(6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text('Only every $weekday'),
                  subtitle: const Text('Off = every class day'),
                  value: sameWeekday,
                  onChanged: (v) => setLocal(() => sameWeekday = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Publish immediately'),
                  value: publish,
                  onChanged: (v) => setLocal(() => publish = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
              child: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
    if (go != true) return;
    try {
      final r = await ref.read(plannerRepositoryProvider).copyDayForward(
            date: widget.date, instituteId: widget.instituteId, academicYear: widget.academicYear,
            shift: widget.shift, classroomName: _classroom, sameWeekday: sameWeekday, publish: publish,
          );
      if (!mounted) return;
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Copied to ${r.daysFilled} day(s) · ${r.classesWritten} classes'),
        backgroundColor: const Color(0xFF16A34A),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Bulk-cancel this classroom's classes across future class days (inverse of copy).
  Future<void> _cancelForward() async {
    if (_classroom == null) {
      setState(() => _error = 'Select a classroom first.');
      return;
    }
    final weekday = DateFormat('EEEE').format(widget.date);
    bool sameWeekday = true;
    bool includeThisDay = true;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Cancel classes forward'),
          content: SizedBox(
            width: MediaQuery.sizeOf(ctx).width * 0.9 < 360 ? MediaQuery.sizeOf(ctx).width * 0.9 : 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancel $_classroom’s classes across future class days for the rest of the term. Records are kept and marked cancelled; attendance is disabled. (Holiday & already-cancelled days are untouched.)',
                  style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary),
                ),
                const Gap(6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text('Only every $weekday'),
                  subtitle: const Text('Off = every class day'),
                  value: sameWeekday,
                  onChanged: (v) => setLocal(() => sameWeekday = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Include this day'),
                  value: includeThisDay,
                  onChanged: (v) => setLocal(() => includeThisDay = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.red, foregroundColor: Colors.white),
              child: const Text('Cancel classes'),
            ),
          ],
        ),
      ),
    );
    if (go != true) return;
    try {
      final r = await ref.read(plannerRepositoryProvider).cancelDayForward(
            date: widget.date, instituteId: widget.instituteId, academicYear: widget.academicYear,
            shift: widget.shift, classroomName: _classroom, sameWeekday: sameWeekday, includeThisDay: includeThisDay,
          );
      if (!mounted) return;
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cancelled ${r.classesCancelled} class(es) across ${r.daysAffected} day(s)'),
      ));
      // If this day's classes were cancelled, refresh the editor to reflect it.
      if (includeThisDay) _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
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
              } else if (v == 'copy') {
                await _copyForward();
              } else if (v == 'cancelForward') {
                await _cancelForward();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copy', child: Text('Copy to future weeks…')),
              PopupMenuItem(value: 'cancelForward', child: Text('Cancel future weeks…')),
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
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(children: [
              Icon(LucideIcons.info, size: 15, color: colors.textSecondary),
              const Gap(8),
              Expanded(
                child: Text(
                  'Edit a period’s subject or teacher below, then Save. Use the trash icon to delete a class; a cancel icon appears once a class is saved (use it if the class was already attended).',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ),
            ]),
          ),
          const Gap(12),
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
              if (_rows[i].existed)
                IconButton(
                  icon: Icon(LucideIcons.ban, size: 17, color: colors.textSecondary),
                  tooltip: 'Cancel this class (keep record)',
                  onPressed: () => _cancelRow(i),
                ),
              IconButton(
                icon: Icon(LucideIcons.trash2, size: 18, color: colors.red),
                tooltip: 'Delete this class',
                onPressed: () => _deleteRow(i),
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
