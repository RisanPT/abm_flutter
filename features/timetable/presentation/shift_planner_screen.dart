import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/planning_models.dart';
import 'package:abm_madrasa/features/timetable/presentation/planner_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/planner_status.dart';
import 'package:abm_madrasa/features/timetable/presentation/widgets/day_timetable_editor.dart';
import 'package:abm_madrasa/features/timetable/presentation/widgets/add_class_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';

const _maroon = Color(0xFF5A2A2A);

class ShiftPlannerScreen extends ConsumerStatefulWidget {
  const ShiftPlannerScreen({super.key});

  @override
  ConsumerState<ShiftPlannerScreen> createState() => _ShiftPlannerScreenState();
}

class _ShiftPlannerScreenState extends ConsumerState<ShiftPlannerScreen> {
  String _shift = 'Shift-1';
  String _academicYear = '2026-2027';
  DateTime _focusedDay = instituteToday();

  String get _instituteId => ref.read(selectedInstituteProvider).id;

  PlannerCalendarProvider get _calProvider =>
      plannerCalendarProvider(_academicYear, _shift, _focusedDay.year, _focusedDay.month);

  PlannerSummaryProvider get _sumProvider =>
      plannerSummaryProvider(_academicYear, _shift, _focusedDay.year, _focusedDay.month);

  PlannerOverviewProvider get _overviewProvider =>
      plannerOverviewProvider(_academicYear, _focusedDay.year, _focusedDay.month);

  void _refresh() {
    ref.invalidate(_calProvider);
    ref.invalidate(_sumProvider);
    ref.invalidate(_overviewProvider);
  }

  DateTime _utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);
  String _key(DateTime d) => _utc(d).toIso8601String();

  // ── Day tap (acts on the active shift tab) ──────────────────────────────────
  Future<void> _onDayTapped(DateTime day, Map<String, OverviewCell> cells) async {
    final status = cells[_key(day)]?.shifts[_shift]?.displayStatus ?? 'Empty';
    final date = _utc(day);

    if (status == 'Empty') {
      final yes = await _confirmIsClassDay(date);
      if (yes != true) return;
      try {
        await ref.read(plannerRepositoryProvider).planDay(
              date: date, instituteId: _instituteId, academicYear: _academicYear, shift: _shift,
            );
        _refresh();
        if (mounted) _openEditor(date);
      } catch (e) {
        _toast(_err(e), error: true);
      }
    } else if (status == 'Holiday') {
      _showHolidayInfo(date);
    } else {
      _openEditor(date);
    }
  }

  // Back that can never trip go_router's "popped the last page" assertion:
  // pop only when there is genuinely something to pop, else go to the dashboard.
  void _goBack() {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.dashboard);
      }
    } catch (_) {
      context.go(RouteNames.dashboard);
    }
  }

  void _openEditor(DateTime date) {
    showDayTimetableEditor(
      context,
      date: date,
      shift: _shift,
      academicYear: _academicYear,
      instituteId: _instituteId,
      onChanged: _refresh,
      onMarkHoliday: () => _markHoliday(date),
      onCancelDay: () => _cancelDay(date),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
  Future<bool?> _confirmIsClassDay(DateTime date) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(LucideIcons.calendarPlus, color: _maroon, size: 32),
        title: Text('Is ${DateFormat('dd MMMM').format(date)} a class day?'),
        content: const Text('Marking it as a class day lets you build its timetable. Non-class days stay disabled everywhere.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
            child: const Text('Yes, plan it'),
          ),
        ],
      ),
    );
  }

  Future<void> _markHoliday(DateTime date) async {
    final reason = await _askReason(date);
    if (reason == null) return; // cancelled
    final repo = ref.read(plannerRepositoryProvider);
    try {
      final res = await repo.markHoliday(
        date: date, instituteId: _instituteId, academicYear: _academicYear, shift: _shift, reason: reason, reschedule: null,
      );
      if (res.needsDecision) {
        await _resolveHolidayWithClasses(date, reason, res.classCount);
      }
      _refresh();
      if (mounted) _toast('Marked ${DateFormat('dd MMM').format(date)} as holiday');
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  Future<void> _resolveHolidayWithClasses(DateTime date, String reason, int classCount) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(LucideIcons.alertTriangle, color: Color(0xFFDD6B20), size: 30),
        title: const Text('This day has classes'),
        content: Text('$classCount scheduled class(es) exist on this day. What should happen to them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, 'back'), child: const Text('Back')),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, 'cancel'), child: const Text('Cancel them')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, 'reschedule'),
            style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
    final repo = ref.read(plannerRepositoryProvider);
    if (choice == 'cancel') {
      await repo.markHoliday(date: date, instituteId: _instituteId, academicYear: _academicYear, shift: _shift, reason: reason, reschedule: false);
    } else if (choice == 'reschedule') {
      final target = await _pickTargetDate(date);
      if (target != null) {
        await repo.markHoliday(
          date: date, instituteId: _instituteId, academicYear: _academicYear, shift: _shift,
          reason: reason, reschedule: true, targetDate: target,
        );
        if (mounted) _toast('Classes moved to ${DateFormat('dd MMM').format(target)}');
      }
    }
  }

  Future<String?> _askReason(DateTime date) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Mark ${DateFormat('dd MMM').format(date)} as Holiday'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason (optional)', hintText: 'e.g. Eid, Public holiday'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC53030), foregroundColor: Colors.white),
            child: const Text('Mark Holiday'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickTargetDate(DateTime source) async {
    final cells = await ref.read(_calProvider.future);
    final candidates = cells
        .where((c) => c.displayStatus != 'Holiday' && c.displayStatus != 'Cancelled' && _key(c.date) != _key(source))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (candidates.isEmpty) {
      _toast('No other class day available this month to reschedule to.', error: true);
      return null;
    }
    DateTime? selected = candidates.first.date;
    return showDialog<DateTime>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Reschedule classes to'),
          content: DropdownButton<DateTime>(
            value: selected,
            isExpanded: true,
            items: candidates
                .map((c) => DropdownMenuItem(
                      value: c.date,
                      child: Text('${DateFormat('dd MMM (EEE)').format(c.date)}  •  ${c.displayStatus}'),
                    ))
                .toList(),
            onChanged: (v) => setLocal(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelDay(DateTime date) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Cancel ${DateFormat('dd MMM').format(date)}?'),
        content: const Text('All classes on this day will be cancelled and attendance disabled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC53030), foregroundColor: Colors.white),
            child: const Text('Cancel Day'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(plannerRepositoryProvider).cancelDay(date: date, instituteId: _instituteId, academicYear: _academicYear, shift: _shift);
      _refresh();
      if (mounted) _toast('Day cancelled');
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  void _showHolidayInfo(DateTime date) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(LucideIcons.ban, color: Color(0xFFC53030), size: 30),
        title: Text('${DateFormat('dd MMMM').format(date)} — Holiday ($_shift)'),
        content: const Text('This day is marked as a holiday for this shift.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(plannerRepositoryProvider).planDay(date: date, instituteId: _instituteId, academicYear: _academicYear, shift: _shift);
              _refresh();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
            child: const Text('Reinstate class day'),
          ),
        ],
      ),
    );
  }

  // ── Bulk plan (weekday pattern → month / year) ──────────────────────────────
  Future<void> _showBulkPlanDialog() async {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selected = <int>{};
    String scope = 'month';

    final apply = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          icon: const Icon(LucideIcons.calendarRange, color: _maroon, size: 30),
          title: const Text('Bulk plan class days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select weekdays', style: context.typography.bodySmallSemiBold.copyWith(color: context.colors.textSecondary)),
              const Gap(8),
              Wrap(
                spacing: 6,
                children: [
                  for (int i = 0; i < 7; i++)
                    FilterChip(
                      label: Text(labels[i]),
                      selected: selected.contains(i),
                      onSelected: (v) => setLocal(() => v ? selected.add(i) : selected.remove(i)),
                    ),
                ],
              ),
              const Gap(16),
              Text('Apply to', style: context.typography.bodySmallSemiBold.copyWith(color: context.colors.textSecondary)),
              const Gap(8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('This month (${DateFormat('MMM yyyy').format(_focusedDay)})'),
                    selected: scope == 'month',
                    onSelected: (_) => setLocal(() => scope = 'month'),
                  ),
                  ChoiceChip(
                    label: Text('Whole year ($_academicYear)'),
                    selected: scope == 'year',
                    onSelected: (_) => setLocal(() => scope = 'year'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selected.isEmpty ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
              child: const Text('Plan'),
            ),
          ],
        ),
      ),
    );

    if (apply != true || selected.isEmpty) return;
    try {
      final res = await ref.read(plannerRepositoryProvider).bulkPlan(
            weekdays: selected.toList()..sort(),
            scope: scope,
            year: _focusedDay.year,
            month: _focusedDay.month,
            academicYear: _academicYear,
            shift: _shift,
            instituteId: _instituteId,
          );
      _refresh();
      if (mounted) {
        _toast('Planned ${res.planned} day(s)${res.skippedExisting > 0 ? ' • ${res.skippedExisting} already planned' : ''}');
      }
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  // ── Default shift schedule (recurring weekdays per shift) ───────────────────
  static const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  Future<void> _showShiftDefaultsDialog() async {
    Map<String, List<int>> defaults;
    try {
      defaults = await ref.read(plannerRepositoryProvider).getShiftDefaults(_instituteId);
    } catch (_) {
      defaults = {};
    }
    final s1 = <int>{...(defaults['Shift-1'] ?? const [])};
    final s2 = <int>{...(defaults['Shift-2'] ?? const [])};
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget shiftRow(String title, Set<int> sel) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.typography.bodyMediumSemiBold),
                  const Gap(6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0; i < 7; i++)
                        FilterChip(
                          label: Text(_weekdayLabels[i]),
                          selected: sel.contains(i),
                          onSelected: (v) => setLocal(() => v ? sel.add(i) : sel.remove(i)),
                        ),
                    ],
                  ),
                ],
              );
          return AlertDialog(
            icon: const Icon(LucideIcons.calendarClock, color: _maroon, size: 28),
            title: const Text('Default Shift Schedule'),
            content: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.9 < 380 ? MediaQuery.sizeOf(context).width * 0.9 : 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set the recurring class weekdays for each shift. You can then auto-fill the whole term for a shift with one tap.',
                      style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary),
                    ),
                    const Gap(16),
                    shiftRow('Shift-1', s1),
                    const Gap(16),
                    shiftRow('Shift-2', s2),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (saved != true) return;
    try {
      await ref.read(plannerRepositoryProvider).setShiftDefaults(_instituteId, {
        'Shift-1': s1.toList()..sort(),
        'Shift-2': s2.toList()..sort(),
      });
      if (mounted) _toast('Default schedule saved');
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  Future<void> _applyDefaultSchedule() async {
    Map<String, List<int>> defaults;
    try {
      defaults = await ref.read(plannerRepositoryProvider).getShiftDefaults(_instituteId);
    } catch (e) {
      _toast(_err(e), error: true);
      return;
    }
    final weekdays = defaults[_shift] ?? const [];
    if (weekdays.isEmpty) {
      if (mounted) _toast('Set a default schedule for $_shift first (Defaults)', error: true);
      return;
    }
    final names = weekdays.map((w) => _weekdayLabels[w]).join(', ');
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(LucideIcons.zap, color: _maroon, size: 28),
        title: Text('Auto-fill $_shift'),
        content: Text('Plan class days on $names for every week of $_academicYear? Existing days are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
            child: const Text('Auto-fill Year'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await ref.read(plannerRepositoryProvider).bulkPlan(
            weekdays: weekdays,
            scope: 'year',
            year: _focusedDay.year,
            month: _focusedDay.month,
            academicYear: _academicYear,
            shift: _shift,
            instituteId: _instituteId,
          );
      _refresh();
      if (mounted) {
        _toast('Auto-filled ${res.planned} class day(s) on $names'
            '${res.skippedExisting > 0 ? ' • ${res.skippedExisting} already planned' : ''}');
      }
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  // ── Teacher leave (reassign to a substitute) ────────────────────────────────
  Future<void> _showTeacherLeaveDialog() async {
    List<TeacherOption> teachers;
    try {
      final data = await ref.read(plannerRepositoryProvider).getDayTimetable(
            date: instituteToday(), instituteId: _instituteId, academicYear: _academicYear, shift: _shift,
          );
      teachers = data.teachers;
    } catch (e) {
      _toast(_err(e), error: true);
      return;
    }
    if (teachers.length < 2) {
      _toast('Need at least two teachers to reassign.', error: true);
      return;
    }

    String? fromId;
    String? toId;
    DateTime fromDate = instituteToday();
    DateTime toDate = instituteToday();

    final apply = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          icon: const Icon(LucideIcons.userMinus, color: _maroon, size: 30),
          title: const Text('Teacher leave — reassign classes'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teacher on leave', style: context.typography.bodySmallSemiBold.copyWith(color: context.colors.textSecondary)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: fromId,
                  hint: const Text('Select teacher'),
                  items: teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))).toList(),
                  onChanged: (v) => setLocal(() { fromId = v; if (toId == v) toId = null; }),
                ),
                const Gap(12),
                Text('Substitute', style: context.typography.bodySmallSemiBold.copyWith(color: context.colors.textSecondary)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: toId,
                  hint: const Text('Select substitute'),
                  items: teachers.where((t) => t.id != fromId).map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))).toList(),
                  onChanged: (v) => setLocal(() => toId = v),
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: fromDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setLocal(() { fromDate = _utc(d); if (toDate.isBefore(fromDate)) toDate = fromDate; });
                        },
                        child: Text('From: ${DateFormat('dd MMM').format(fromDate)}'),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: toDate, firstDate: fromDate, lastDate: DateTime(2100));
                          if (d != null) setLocal(() => toDate = _utc(d));
                        },
                        child: Text('To: ${DateFormat('dd MMM').format(toDate)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (fromId != null && toId != null) ? () => Navigator.pop(context, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
              child: const Text('Reassign'),
            ),
          ],
        ),
      ),
    );

    if (apply != true || fromId == null || toId == null) return;
    try {
      final res = await ref.read(plannerRepositoryProvider).reassignTeacher(
            fromTeacherId: fromId!,
            toTeacherId: toId!,
            fromDate: fromDate,
            toDate: toDate,
            shift: _shift,
            academicYear: _academicYear,
            instituteId: _instituteId,
          );
      _refresh();
      if (mounted) {
        final skipped = res.conflicts.isNotEmpty ? ' • ${res.conflicts.length} skipped (substitute busy)' : '';
        _toast('Reassigned ${res.reassigned} class(es)$skipped', error: res.reassigned == 0 && res.conflicts.isNotEmpty);
      }
    } catch (e) {
      _toast(_err(e), error: true);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final overviewAsync = ref.watch(_overviewProvider);

    final cells = <String, OverviewCell>{
      for (final c in overviewAsync.asData?.value ?? const <OverviewCell>[]) _key(c.date): c,
    };

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _buildHeader(colors),
          // Header stays fixed; everything below scrolls so the calendar never
          // overflows on short viewports.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryBar(),
                  Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          TableCalendar(
                            firstDay: DateTime(2020),
                            lastDay: DateTime(2100),
                            focusedDay: _focusedDay,
                            currentDay: instituteToday(), // "today" highlight in Saudi time
                            rowHeight: 96,
                            daysOfWeekHeight: 40,
                            headerVisible: false,
                            availableGestures: AvailableGestures.horizontalSwipe,
                            selectedDayPredicate: (_) => false,
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() => _focusedDay = focusedDay);
                              _onDayTapped(selectedDay, cells);
                            },
                            onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (c, day, _) => _cell(day, cells[_key(day)]),
                              selectedBuilder: (c, day, _) => _cell(day, cells[_key(day)]),
                              todayBuilder: (c, day, _) => _cell(day, cells[_key(day)], isToday: true),
                              outsideBuilder: (c, day, _) => _cell(day, cells[_key(day)], isOutside: true),
                            ),
                          ),
                          if (overviewAsync.isLoading)
                            const Positioned(top: 8, right: 8, child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                        ],
                      ),
                    ),
                  ),
                  _buildLegend(colors),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorExtension colors) {
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: colors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final back = IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack);
            final titleCol = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift Planner', style: typography.h3.copyWith(color: _maroon)),
                const Gap(2),
                Text('Master academic calendar — plan class days, build timetables, publish.',
                    style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            );
            final addBtn = ElevatedButton.icon(
              onPressed: () => showAddClassSheet(context,
                  instituteId: _instituteId, initialDate: _focusedDay, initialShift: _shift, onSaved: _refresh),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Class'),
              style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white),
            );
            final bulkBtn = OutlinedButton.icon(
              onPressed: _showBulkPlanDialog,
              icon: const Icon(LucideIcons.calendarRange, size: 18),
              label: const Text('Bulk Plan'),
              style: OutlinedButton.styleFrom(foregroundColor: _maroon),
            );
            final leaveBtn = OutlinedButton.icon(
              onPressed: _showTeacherLeaveDialog,
              icon: const Icon(LucideIcons.userMinus, size: 18),
              label: const Text('Teacher Leave'),
              style: OutlinedButton.styleFrom(foregroundColor: _maroon),
            );
            final defaultsBtn = OutlinedButton.icon(
              onPressed: _showShiftDefaultsDialog,
              icon: const Icon(LucideIcons.calendarClock, size: 18),
              label: const Text('Defaults'),
              style: OutlinedButton.styleFrom(foregroundColor: _maroon),
            );
            final autofillBtn = ElevatedButton.icon(
              onPressed: _applyDefaultSchedule,
              icon: const Icon(LucideIcons.zap, size: 18),
              label: Text('Auto-fill $_shift'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _maroon.withValues(alpha: 0.9), foregroundColor: Colors.white),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [back, Expanded(child: titleCol)]),
                const Gap(12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  addBtn, defaultsBtn, autofillBtn, bulkBtn, leaveBtn,
                ]),
              ],
            );
          }),
          const Gap(20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _focusedDay = instituteToday()),
                child: const Text('Today', style: TextStyle(color: Colors.black87)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(8)),
                    child: Text(DateFormat('MMMM yyyy').format(_focusedDay),
                        style: typography.bodyMediumSemiBold.copyWith(color: _maroon)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _academicYear,
                    style: typography.bodyMediumSemiBold.copyWith(color: _maroon),
                    items: ['2025-2026', '2026-2027', '2027-2028']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _academicYear = v ?? _academicYear),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [_shiftTab('Shift-1'), _shiftTab('Shift-2')]),
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
      onTap: () => setState(() => _shift = shift),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _maroon.withValues(alpha: 0.1) : Colors.transparent,
          border: shift == 'Shift-1' ? Border(right: BorderSide(color: context.colors.border)) : null,
        ),
        child: Text(shift,
            style: context.typography.bodyMediumSemiBold.copyWith(color: selected ? _maroon : context.colors.textSecondary)),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final sumAsync = ref.watch(_sumProvider);
    final s = sumAsync.asData?.value;
    final items = <(String, String, IconData, Color)>[
      ('Planned Days', '${s?.plannedDays ?? '—'}', LucideIcons.calendarCheck, const Color(0xFFB7791F)),
      ('Holidays', '${s?.holidays ?? '—'}', LucideIcons.ban, const Color(0xFFC53030)),
      ('Draft', '${s?.draftTimetables ?? '—'}', LucideIcons.fileEdit, const Color(0xFFDD6B20)),
      ('Published', '${s?.publishedTimetables ?? '—'}', LucideIcons.checkCircle2, const Color(0xFF2F855A)),
      ('Classes', '${s?.scheduledClasses ?? '—'}', LucideIcons.bookOpen, _maroon),
      ('Teachers', '${s?.teachersAssigned ?? '—'}', LucideIcons.users, const Color(0xFF4A5568)),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [for (final it in items) _summaryCard(it.$1, it.$2, it.$3, it.$4)]),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    final typography = context.typography;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minWidth: 130),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: typography.h4.copyWith(color: color)),
              Text(label, style: typography.bodySmall.copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(DateTime day, OverviewCell? cell, {bool isToday = false, bool isOutside = false}) {
    final colors = context.colors;
    final typography = context.typography;
    // The cell reflects the ACTIVE shift tab; the other shift is just a small badge.
    final active = cell?.shifts[_shift];
    final otherShift = _shift == 'Shift-1' ? 'Shift-2' : 'Shift-1';
    final other = cell?.shifts[otherShift];
    final activeHas = active != null && active.displayStatus != 'Empty';
    final otherHas = other != null && other.displayStatus != 'Empty';
    final style = plannerStatusStyle(active?.displayStatus ?? 'Empty');

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border, width: 0.5),
          right: BorderSide(color: colors.border, width: 0.5),
        ),
        color: isOutside ? colors.background.withValues(alpha: 0.4) : Colors.white,
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: _maroon, borderRadius: BorderRadius.circular(20)),
                  child: Text('${day.day}', style: typography.bodySmallSemiBold.copyWith(color: Colors.white)),
                )
              else
                Text('${day.day}',
                    style: typography.bodyMediumSemiBold.copyWith(
                      color: isOutside ? colors.textSecondary.withValues(alpha: 0.5) : _maroon,
                    )),
              // Small hint that the OTHER shift also has classes that day.
              if (otherHas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: plannerStatusStyle(other.displayStatus).color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${otherShift == 'Shift-1' ? 'S1' : 'S2'}·${other.classCount}',
                      style: typography.bodySmall.copyWith(fontSize: 8, color: plannerStatusStyle(other.displayStatus).color)),
                ),
            ],
          ),
          const Spacer(),
          if (activeHas)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.1),
                border: Border(left: BorderSide(color: style.color, width: 3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(active.displayStatus, style: typography.bodySmallSemiBold.copyWith(color: style.color, fontSize: 11)),
                  if (active.classCount > 0)
                    Text('${active.classCount} class${active.classCount == 1 ? '' : 'es'}',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10)),
                ],
              ),
            )
          else if (!isOutside)
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(LucideIcons.plus, size: 14, color: colors.textSecondary.withValues(alpha: 0.35)),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(ColorExtension colors) {
    const statuses = ['Planned', 'Draft', 'Published', 'Holiday', 'Completed', 'Cancelled'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          for (final s in statuses)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: plannerStatusStyle(s).color, borderRadius: BorderRadius.circular(3))),
                const Gap(6),
                Text(s, style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFC53030) : const Color(0xFF2F855A),
    ));
  }

  String _err(Object e) => describeApiError(e);
}
