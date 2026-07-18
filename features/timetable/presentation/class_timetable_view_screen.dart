import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/planning_models.dart';
import 'package:abm_madrasa/features/timetable/presentation/planner_status.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _maroon = Color(0xFF5A2A2A);

/// Read-only viewer: pick Shift + Class + Date → instantly see that class's
/// timetable for the date, reflecting the shift allocation.
class ClassTimetableViewScreen extends ConsumerStatefulWidget {
  const ClassTimetableViewScreen({super.key});

  @override
  ConsumerState<ClassTimetableViewScreen> createState() => _ClassTimetableViewScreenState();
}

class _ClassTimetableViewScreenState extends ConsumerState<ClassTimetableViewScreen> {
  String _shift = 'Shift-1';
  String? _class;
  DateTime _date = instituteToday();

  bool _loading = true;
  String? _error;
  DayTimetable? _data;
  List<ClassroomOption> _classrooms = const [];

  DateTime get _utcDate => DateTime.utc(_date.year, _date.month, _date.day);
  String get _instituteId => ref.read(selectedInstituteProvider).id;
  String _academicYear(DateTime d) => d.month >= 6 ? '${d.year}-${d.year + 1}' : '${d.year - 1}-${d.year}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(plannerRepositoryProvider).getDayTimetable(
            date: _utcDate,
            instituteId: _instituteId,
            academicYear: _academicYear(_date),
            shift: _shift,
            classroom: _class,
          );
      _data = data;
      if (_classrooms.isEmpty) _classrooms = data.classrooms;
      _class ??= _classrooms.isNotEmpty ? _classrooms.first.name : null;
    } catch (e) {
      _error = describeApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DayPeriod> get _periods {
    final all = _data?.periods ?? const [];
    final filtered = _class == null ? all : all.where((p) => p.classroomName == _class).toList();
    return [...filtered]..sort((a, b) => a.period.compareTo(b.period));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _maroon,
        elevation: 0,
        title: Text('Class Timetable', style: typography.h4.copyWith(color: _maroon)),
      ),
      body: Column(
        children: [
          _filterBar(colors, typography),
          const Divider(height: 1),
          Expanded(child: _body(colors, typography)),
        ],
      ),
    );
  }

  Widget _filterBar(ColorExtension colors, TypographyExtension typography) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Shift toggle
              Container(
                decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [_shiftTab('Shift-1'), _shiftTab('Shift-2')]),
              ),
              const Gap(12),
              // Class dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _classrooms.any((c) => c.name == _class) ? _class : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _classrooms.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setState(() => _class = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const Gap(12),
          // Date navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _date = _date.subtract(const Duration(days: 1)));
                  _load();
                },
              ),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.calendar, size: 16),
                  label: Text(DateFormat('EEEE, dd MMMM yyyy').format(_date)),
                  style: OutlinedButton.styleFrom(foregroundColor: _maroon, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) {
                      setState(() => _date = d);
                      _load();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _date = _date.add(const Duration(days: 1)));
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shiftTab(String shift) {
    final selected = _shift == shift;
    return InkWell(
      onTap: () {
        setState(() => _shift = shift);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _maroon.withValues(alpha: 0.1) : Colors.transparent,
          border: shift == 'Shift-1' ? Border(right: BorderSide(color: context.colors.border)) : null,
        ),
        child: Text(shift, style: context.typography.bodySmallSemiBold.copyWith(color: selected ? _maroon : context.colors.textSecondary)),
      ),
    );
  }

  Widget _body(ColorExtension colors, TypographyExtension typography) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));

    final data = _data;
    // Day-level states first.
    if (data == null || !data.isPlanned) return _empty(colors, typography, LucideIcons.calendarX, 'Not a class day', 'This date is not planned for $_shift.');
    if (data.isHoliday) return _empty(colors, typography, LucideIcons.ban, 'Holiday', 'No classes scheduled on this date.');

    final periods = _periods;
    if (_class == null) return _empty(colors, typography, LucideIcons.school, 'Select a class', 'Choose a class to view its timetable.');
    if (periods.isEmpty) return _empty(colors, typography, LucideIcons.coffee, 'No classes', 'No periods for $_class on this date.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (_, i) => _periodTile(periods[i], colors, typography),
    );
  }

  Widget _periodTile(DayPeriod p, ColorExtension colors, TypographyExtension typography) {
    final style = plannerStatusStyle(p.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(p.startTime.isEmpty ? '—' : p.startTime, style: typography.bodyMediumSemiBold.copyWith(color: _maroon)),
              Text(p.endTime, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
            ],
          ),
          const Gap(14),
          Container(width: 1, height: 40, color: colors.border),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Period ${p.period} • ${p.subjectName}', style: typography.bodyMediumSemiBold),
                Text(
                  [if (p.teacherName != null && p.teacherName!.isNotEmpty) p.teacherName!, if (p.room.isNotEmpty) 'Room ${p.room}'].join('  •  '),
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: style.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(style.label, style: typography.bodySmall.copyWith(color: style.color)),
          ),
        ],
      ),
    );
  }

  Widget _empty(ColorExtension colors, TypographyExtension typography, IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
          const Gap(12),
          Text(title, style: typography.bodyLargeSemiBold.copyWith(color: colors.textSecondary)),
          const Gap(4),
          Text(subtitle, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
