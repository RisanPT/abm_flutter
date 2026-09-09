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

/// Read-only, whole-day timetable grid — every class and period at a glance,
/// laid out like a printed timetable (periods down, classes across). Opens as a
/// dialog from the Shift Planner when a planned day is tapped. Admins get an
/// Edit action (whole day, or tap a class column to edit that class).
Future<void> showDayTimetableView(
  BuildContext context, {
  required DateTime date,
  required String shift,
  required String academicYear,
  required String instituteId,
  required bool canEdit,
  required VoidCallback onEditDay,
  void Function(String classroom)? onEditClass,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => DayTimetableView(
      date: date,
      shift: shift,
      academicYear: academicYear,
      instituteId: instituteId,
      canEdit: canEdit,
      onEditDay: onEditDay,
      onEditClass: onEditClass,
    ),
  );
}

class DayTimetableView extends ConsumerStatefulWidget {
  const DayTimetableView({
    super.key,
    required this.date,
    required this.shift,
    required this.academicYear,
    required this.instituteId,
    required this.canEdit,
    required this.onEditDay,
    this.onEditClass,
  });

  final DateTime date;
  final String shift;
  final String academicYear;
  final String instituteId;
  final bool canEdit;
  final VoidCallback onEditDay;
  final void Function(String classroom)? onEditClass;

  @override
  ConsumerState<DayTimetableView> createState() => _DayTimetableViewState();
}

class _DayTimetableViewState extends ConsumerState<DayTimetableView> {
  bool _loading = true;
  String? _error;
  DayTimetable? _data;

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
      final data = await ref.read(plannerRepositoryProvider).getDayTimetable(
            date: widget.date,
            instituteId: widget.instituteId,
            academicYear: widget.academicYear,
            shift: widget.shift,
          );
      _data = data;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _editClass(String classroom) {
    Navigator.of(context).pop();
    widget.onEditClass?.call(classroom);
  }

  void _editDay() {
    Navigator.of(context).pop();
    widget.onEditDay();
  }

  // Natural-ish sort so STD-2 < STD-10.
  int _cmpClass(String a, String b) {
    int? na = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '');
    int? nb = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '');
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 32, vertical: isMobile ? 16 : 32),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1000, maxHeight: size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(colors),
            Divider(height: 1, color: colors.border),
            Flexible(child: _body(colors, isMobile)),
            if (_hasGrid) ...[
              Divider(height: 1, color: colors.border),
              _footer(colors),
            ],
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header(ColorExtension colors) {
    final typography = context.typography;
    final status = _data?.isHoliday == true ? 'Holiday' : (_data?.dayStatus ?? 'Planned');
    final style = plannerStatusStyle(status);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      color: _maroon.withValues(alpha: 0.04),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _maroon.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.calendarDays, color: _maroon, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, dd MMMM yyyy').format(widget.date),
                    style: typography.bodyLargeSemiBold.copyWith(color: _maroon), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap(3),
                Row(
                  children: [
                    _pill(widget.shift, _maroon),
                    const Gap(6),
                    _pill(style.label, style.color, icon: style.icon),
                  ],
                ),
              ],
            ),
          ),
          if (widget.canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _editDay,
                icon: const Icon(LucideIcons.pencil, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: _maroon),
              ),
            ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            color: colors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const Gap(4)],
          Text(text, style: context.typography.bodySmall.copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _body(ColorExtension colors, bool isMobile) {
    if (_loading) return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    if (_error != null) return _empty(colors, LucideIcons.alertTriangle, 'Couldn’t load', _error!);

    final data = _data;
    if (data == null || !data.isPlanned) {
      return _empty(colors, LucideIcons.calendarX, 'Not a class day', 'This date isn’t planned for ${widget.shift}.');
    }
    if (data.isHoliday) {
      return _empty(colors, LucideIcons.ban, 'Holiday', 'No classes are scheduled on this day.');
    }

    final periods = data.periods;
    if (periods.isEmpty) {
      return _empty(
        colors, LucideIcons.coffee, 'No timetable yet',
        widget.canEdit ? 'This day is planned but empty. Tap Edit to build its timetable.' : 'No periods have been added for this day.',
        action: widget.canEdit
            ? ElevatedButton.icon(
                onPressed: _editDay,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Build timetable'),
                style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
              )
            : null,
      );
    }

    final classes = periods.map((p) => p.classroomName).where((s) => s.isNotEmpty).toSet().toList()..sort(_cmpClass);
    final periodNums = periods.map((p) => p.period).toSet().toList()..sort();
    final cell = <String, DayPeriod>{}; // "class|period" -> period
    final timeOf = <int, String>{};
    for (final p in periods) {
      cell['${p.classroomName}|${p.period}'] = p;
      if ((timeOf[p.period] ?? '').isEmpty && p.startTime.isNotEmpty) {
        timeOf[p.period] = p.endTime.isNotEmpty ? '${p.startTime}–${p.endTime}' : p.startTime;
      }
    }

    const periodColW = 74.0;
    final classColW = isMobile ? 126.0 : 158.0;

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row
            Row(
              children: [
                _corner(periodColW),
                for (final c in classes) _classHeader(c, classColW),
              ],
            ),
            // period rows
            for (final n in periodNums)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _periodLabel(n, timeOf[n] ?? '', periodColW),
                    for (final c in classes) _gridCell(cell['$c|$n'], c, classColW, colors),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _hasGrid {
    final d = _data;
    return !_loading && _error == null && d != null && d.isPlanned && !d.isHoliday && d.periods.isNotEmpty;
  }

  Widget _corner(double w) => Container(
        width: w,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _maroon, border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.15)))),
        child: const Icon(LucideIcons.clock, size: 15, color: Colors.white),
      );

  Widget _classHeader(String name, double w) => Container(
        width: w,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _maroon,
          border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        ),
        child: Text(name,
            style: context.typography.bodyMediumSemiBold.copyWith(color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  Widget _periodLabel(int n, String time, double w) {
    final colors = context.colors;
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _maroon.withValues(alpha: 0.06),
        border: Border(top: BorderSide(color: colors.border), right: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('P$n', style: context.typography.bodyMediumSemiBold.copyWith(color: _maroon)),
          if (time.isNotEmpty) ...[
            const Gap(2),
            Text(time, textAlign: TextAlign.center, style: context.typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 9.5)),
          ],
        ],
      ),
    );
  }

  Widget _gridCell(DayPeriod? p, String cls, double w, ColorExtension colors) {
    final typography = context.typography;
    if (p == null || p.subjectName.isEmpty) {
      return Container(
        width: w,
        decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border), left: BorderSide(color: colors.border))),
        alignment: Alignment.center,
        child: Text('—', style: typography.bodySmall.copyWith(color: colors.textSecondary.withValues(alpha: 0.4))),
      );
    }
    final cancelled = p.status == 'Cancelled';
    final style = plannerStatusStyle(p.status);
    final tappable = widget.canEdit && widget.onEditClass != null;
    return InkWell(
      onTap: tappable ? () => _editClass(cls) : null,
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cancelled ? colors.background.withValues(alpha: 0.5) : style.color.withValues(alpha: 0.06),
          border: Border(
            top: BorderSide(color: colors.border),
            left: BorderSide(color: colors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              p.subjectName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.bodyMediumSemiBold.copyWith(
                color: cancelled ? colors.textSecondary : _maroon,
                decoration: cancelled ? TextDecoration.lineThrough : null,
                height: 1.1,
              ),
            ),
            if ((p.teacherName ?? '').isNotEmpty) ...[
              const Gap(3),
              Text(
                p.teacherName!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10.5,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
            if (cancelled) ...[
              const Gap(3),
              Text('Cancelled', style: typography.bodySmall.copyWith(color: style.color, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _footer(ColorExtension colors) {
    final tappable = widget.canEdit && widget.onEditClass != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 13, color: colors.textSecondary),
          const Gap(6),
          Expanded(
            child: Text(
              tappable ? 'Tap any class column to edit that class’s timetable.' : 'Read-only timetable view.',
              style: context.typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
            ),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close', style: TextStyle(color: _maroon))),
        ],
      ),
    );
  }

  Widget _empty(ColorExtension colors, IconData icon, String title, String subtitle, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: colors.textSecondary.withValues(alpha: 0.4)),
          const Gap(12),
          Text(title, style: context.typography.bodyLargeSemiBold.copyWith(color: colors.textSecondary)),
          const Gap(4),
          Text(subtitle, textAlign: TextAlign.center, style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
          if (action != null) ...[const Gap(16), action],
        ],
      ),
    );
  }
}
