import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _maroon = Color(0xFF5A2A2A);
const _statuses = ['Present', 'Absent', 'Late'];

/// Attendance sheet for one published scheduled class.
Future<void> showClassAttendanceSheet(
  BuildContext context, {
  required String scheduledClassId,
  required String classroomName,
  required String subjectName,
  required int period,
  String shift = '',
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => ClassAttendanceSheet(
      scheduledClassId: scheduledClassId,
      classroomName: classroomName,
      subjectName: subjectName,
      period: period,
      shift: shift,
      onSaved: onSaved,
    ),
  );
}

class ClassAttendanceSheet extends ConsumerStatefulWidget {
  const ClassAttendanceSheet({
    super.key,
    required this.scheduledClassId,
    required this.classroomName,
    required this.subjectName,
    required this.period,
    this.shift = '',
    this.onSaved,
  });

  final String scheduledClassId;
  final String classroomName;
  final String subjectName;
  final int period;
  final String shift;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ClassAttendanceSheet> createState() => _ClassAttendanceSheetState();
}

class _ClassAttendanceSheetState extends ConsumerState<ClassAttendanceSheet> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<StudentModel> _students = [];
  final Map<String, String> _status = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final instituteId = ref.read(selectedInstituteProvider).id;
      final allStudents = await ref.read(studentRepositoryProvider).getStudents(
            classroom: widget.classroomName,
            instituteId: instituteId,
          );
      // Restrict the roster to this class's shift (a classroom can host a
      // different group of students per shift).
      final students = widget.shift.isEmpty
          ? allStudents
          : allStudents.where((s) => s.shift == widget.shift).toList();
      final existing = await ref.read(plannerRepositoryProvider).getClassAttendance(
            scheduledClassId: widget.scheduledClassId,
            type: 'Student',
            instituteId: instituteId,
          );
      _students = students;
      for (final s in students) {
        _status[s.id] = existing[s.id] ?? 'Present';
      }
    } catch (e) {
      _error = describeApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(plannerRepositoryProvider).markClassAttendance(
            scheduledClassId: widget.scheduledClassId,
            type: 'Student',
            records: _students.map((s) => {'studentId': s.id, 'status': _status[s.id] ?? 'Present'}).toList(),
          );
      widget.onSaved?.call();
      if (mounted) {
        // Capture the messenger before popping — after pop this State is
        // unmounted and its context is defunct.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(const SnackBar(
          content: Text('Attendance saved'),
          backgroundColor: Color(0xFF2F855A),
        ));
      }
    } catch (e) {
      setState(() => _error = describeApiError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _markAllPresent() {
    setState(() {
      for (final s in _students) {
        _status[s.id] = 'Present';
      }
    });
  }

  Color _statusColor(String s) => switch (s) {
        'Present' => const Color(0xFF2F855A),
        'Late' => const Color(0xFFDD6B20),
        _ => const Color(0xFFC53030),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final total = _students.length;
    final present = _status.values.where((v) => v == 'Present').length;
    final late = _status.values.where((v) => v == 'Late').length;
    final absent = _status.values.where((v) => v == 'Absent').length;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle.
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999)),
            ),
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: _maroon.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(LucideIcons.clipboardCheck, color: _maroon, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.classroomName,
                            style: typography.bodyLargeSemiBold.copyWith(color: _maroon),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Period ${widget.period} • ${widget.subjectName}',
                            style: typography.bodySmall.copyWith(color: colors.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            // Count + bulk action.
            if (!_loading && _students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Text('$total ${total == 1 ? 'student' : 'students'}',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _markAllPresent,
                      icon: const Icon(LucideIcons.checkCheck, size: 16),
                      label: const Text('Mark all present'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2F855A),
                        textStyle: typography.bodySmallSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            Divider(height: 1, color: colors.border),
            // Body.
            if (_loading)
              const Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: _maroon))
            else if (_students.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No students in ${widget.classroomName}.',
                    style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _students.length,
                  separatorBuilder: (_, _) => Divider(height: 1, indent: 64, color: colors.border.withValues(alpha: 0.5)),
                  itemBuilder: (_, i) {
                    final s = _students[i];
                    final current = _status[s.id] ?? 'Present';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _maroon.withValues(alpha: 0.1),
                            child: Text(s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?',
                                style: typography.bodyMediumSemiBold.copyWith(color: _maroon)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.fullName,
                                    style: typography.bodyMediumSemiBold,
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (s.admissionNumber.isNotEmpty)
                                  Text('Adm: ${s.admissionNumber}',
                                      style: typography.caption.copyWith(color: colors.textSecondary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusSelector(
                            current: current,
                            colorOf: _statusColor,
                            onChanged: (st) => setState(() => _status[s.id] = st),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(_error!, style: typography.bodySmall.copyWith(color: colors.red)),
              ),
            // Footer: tally + save.
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_loading && _students.isNotEmpty) ...[
                    Row(
                      children: [
                        _Tally(color: const Color(0xFF2F855A), label: 'Present', value: present),
                        const SizedBox(width: 14),
                        _Tally(color: const Color(0xFFDD6B20), label: 'Late', value: late),
                        const SizedBox(width: 14),
                        _Tally(color: const Color(0xFFC53030), label: 'Absent', value: absent),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving || _students.isEmpty ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.save, size: 18),
                      label: Text(_saving ? 'Saving…' : 'Save Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _maroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        textStyle: typography.bodyLargeSemiBold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact, touch-friendly Present / Absent / Late segmented control.
class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.current, required this.colorOf, required this.onChanged});
  final String current;
  final Color Function(String) colorOf;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFF1F1EF), borderRadius: BorderRadius.circular(11)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _statuses.map((st) {
          final selected = current == st;
          final color = colorOf(st);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(st),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                st[0],
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$value $label',
            style: context.typography.bodySmall.copyWith(color: const Color(0xFF4A5568), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
