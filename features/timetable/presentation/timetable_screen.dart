import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/features/timetable/domain/timetable_model.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/widgets/timetable_assignment_dialog.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:abm_madrasa/features/classrooms/presentation/widgets/classroom_subjects_dialog.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  String _selectedClass = 'All Classes';
  String _selectedTeacherId = 'all';
  String _selectedShift = 'Shift-1';
  DateTime _focusedMonth = DateTime.now();

  String get _academicYear =>
      deriveAcademicYear(_focusedMonth.year, _focusedMonth.month);
  int get _year => _focusedMonth.year;
  int get _month => _focusedMonth.month;

  ({String shift, int year, int month, String academicYear}) get _args => (
    shift: _selectedShift,
    year: _year,
    month: _month,
    academicYear: _academicYear,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final timetableAsync = ref.watch(timetableDataProvider(_args));
    final scheduledDatesAsync = ref.watch(scheduledDatesProvider(_args));
    final userRole = ref.watch(authControllerProvider).asData?.value?.role;
    final allowedModules = userRole != null
        ? ref
              .read(permissionControllerProvider.notifier)
              .getPermissionsForRole(userRole)
        : <String>{};
    final canEdit = userRole?.canEditTimetable(allowedModules) ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      body: timetableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load timetable: $error')),
        data: (data) {
          final filteredEntries = data.schedule.where((entry) {
            final classMatches =
                _selectedClass == 'All Classes' ||
                entry.className == _selectedClass;
            final teacherMatches =
                _selectedTeacherId == 'all' ||
                entry.teacherId == _selectedTeacherId;
            return classMatches && teacherMatches;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 24,
                    24,
                    28,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: AbmPatternPainter(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Shift Tabs ────────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildShiftTab('Shift-1', colors),
                                ),
                                Expanded(
                                  child: _buildShiftTab('Shift-2', colors),
                                ),
                              ],
                            ),
                          ),
                          const Gap(16),
                          // ── Title + Actions ───────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Timetable — ${DateFormat('MMMM yyyy').format(_focusedMonth)}',
                                      style: typography.h2.copyWith(
                                        color: colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Gap(4),
                                    Text(
                                      'Academic Year: $_academicYear  •  $_selectedShift',
                                      style: typography.bodyMedium.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.78,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    context.push(RouteNames.classTimetableView),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  foregroundColor: colors.white,
                                ),
                                icon: const Icon(LucideIcons.search, size: 18),
                                label: const Text('View by Date'),
                              ),
                              const Gap(10),
                              if (canEdit) ...[
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.push(RouteNames.shiftPlanner),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.white.withValues(
                                      alpha: 0.15,
                                    ),
                                    foregroundColor: colors.white,
                                  ),
                                  icon: const Icon(
                                    LucideIcons.calendarCheck,
                                    size: 18,
                                  ),
                                  label: const Text('Shift Planner'),
                                ),
                                const Gap(10),
                                ElevatedButton.icon(
                                  onPressed: _selectedClass == 'All Classes'
                                      ? null
                                      : () => _showSubjectDialog(context, data),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    foregroundColor: colors.white,
                                    disabledBackgroundColor: colors.white
                                        .withValues(alpha: 0.08),
                                    disabledForegroundColor: colors.white
                                        .withValues(alpha: 0.4),
                                  ),
                                  icon: const Icon(
                                    LucideIcons.listTodo,
                                    size: 18,
                                  ),
                                  label: const Text('Define Subjects'),
                                ),
                                // const Gap(10),
                                // ElevatedButton.icon(
                                //   onPressed: () => _showAssignmentDialog(context, data),
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: colors.white,
                                //     foregroundColor: colors.primary,
                                //   ),
                                //   icon: const Icon(LucideIcons.userPlus, size: 18),
                                //   label: const Text('Plan Timetable'),
                                // ),
                              ],
                            ],
                          ),
                          const Gap(16),
                          // ── Month Navigation ──────────────────────────────
                          Row(
                            children: [
                              _buildMonthNavButton(
                                icon: LucideIcons.chevronLeft,
                                onPressed: () {
                                  setState(() {
                                    _focusedMonth = DateTime(
                                      _focusedMonth.year,
                                      _focusedMonth.month - 1,
                                    );
                                  });
                                },
                              ),
                              const Gap(8),
                              _buildMonthNavButton(
                                icon: LucideIcons.chevronRight,
                                onPressed: () {
                                  setState(() {
                                    _focusedMonth = DateTime(
                                      _focusedMonth.year,
                                      _focusedMonth.month + 1,
                                    );
                                  });
                                },
                              ),
                              const Gap(16),
                              OutlinedButton(
                                onPressed: () {
                                  setState(
                                    () => _focusedMonth = DateTime.now(),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.white,
                                  side: BorderSide(
                                    color: colors.white.withValues(alpha: 0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: const Text('This Month'),
                              ),
                              const Spacer(),
                              // Scheduled dates count badge
                              scheduledDatesAsync.when(
                                data: (dates) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.calendarDays,
                                        size: 14,
                                        color: colors.white,
                                      ),
                                      const Gap(6),
                                      Text(
                                        '${dates.length} date${dates.length == 1 ? '' : 's'} scheduled',
                                        style: typography.bodySmall.copyWith(
                                          color: colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const Gap(16),
                          // ── Class / Teacher Filters ───────────────────────
                          if (context.isMobile)
                            Column(
                              children: [
                                _buildClassSelector(context, data),
                                const Gap(12),
                                _buildTeacherSelector(context, data),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: _buildClassSelector(context, data),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: _buildTeacherSelector(context, data),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: context.isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _ScheduleBoard(
                                entries: filteredEntries,
                                scheduledDatesAsync: scheduledDatesAsync,
                              ),
                            ),
                            const Gap(20),
                            Expanded(
                              child: _TimetableSummary(
                                data: data,
                                visibleEntries: filteredEntries,
                                scheduledDatesAsync: scheduledDatesAsync,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _TimetableSummary(
                              data: data,
                              visibleEntries: filteredEntries,
                              scheduledDatesAsync: scheduledDatesAsync,
                            ),
                            const Gap(16),
                            _ScheduleBoard(
                              entries: filteredEntries,
                              scheduledDatesAsync: scheduledDatesAsync,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShiftTab(String shift, ColorExtension colors) {
    final isSelected = _selectedShift == shift;
    return InkWell(
      onTap: () {
        if (_selectedShift != shift) {
          setState(() => _selectedShift = shift);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          shift,
          style: context.typography.bodySmallSemiBold.copyWith(
            color: isSelected
                ? colors.primary
                : colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: context.colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: context.colors.white, size: 18),
        ),
      ),
    );
  }

  void _showAssignmentDialog(BuildContext context, TimetableData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TimetableAssignmentDialog(
        data: data,
        shift: _selectedShift,
        year: _year,
        month: _month,
        academicYear: _academicYear,
        initialClassName: _selectedClass == 'All Classes'
            ? null
            : _selectedClass,
      ),
    ).then((_) {
      // Refresh timetable and scheduled dates after dialog closes
      ref.invalidate(timetableDataProvider(_args));
      ref.invalidate(scheduledDatesProvider(_args));
    });
  }

  void _showSubjectDialog(BuildContext context, TimetableData data) {
    final classroom = data.allClassrooms.firstWhere(
      (c) => c.name == _selectedClass,
    );
    showDialog(
      context: context,
      builder: (context) => ClassroomSubjectsDialog(classroom: classroom),
    ).then((_) {
      ref.invalidate(classroomControllerProvider);
      ref.invalidate(timetableDataProvider(_args));
    });
  }

  Widget _buildClassSelector(BuildContext context, TimetableData data) {
    final colors = context.colors;
    final items = ['All Classes', ...data.classes];
    if (!items.contains(_selectedClass)) {
      _selectedClass = 'All Classes';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedClass,
            dropdownColor: colors.white,
            isExpanded: true,
            iconEnabledColor: colors.white,
            style: context.typography.bodyMedium.copyWith(color: colors.white),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: context.typography.bodyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedClass = value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherSelector(BuildContext context, TimetableData data) {
    final colors = context.colors;
    final teacherIds = {'all', ...data.teachers.map((teacher) => teacher.id)};
    if (!teacherIds.contains(_selectedTeacherId)) {
      _selectedTeacherId = 'all';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedTeacherId,
            dropdownColor: colors.white,
            isExpanded: true,
            iconEnabledColor: colors.white,
            style: context.typography.bodyMedium.copyWith(color: colors.white),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(
                  'All Teachers',
                  style: context.typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              ...data.teachers.map(
                (teacher) => DropdownMenuItem(
                  value: teacher.id,
                  child: Text(
                    teacher.fullName,
                    style: context.typography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedTeacherId = value);
              }
            },
          ),
        ),
      ),
    );
  }
}

// ─── Schedule Board ──────────────────────────────────────────────────────────

class _ScheduleBoard extends StatelessWidget {
  const _ScheduleBoard({
    required this.entries,
    required this.scheduledDatesAsync,
  });

  final List<TimetableEntry> entries;
  final AsyncValue<List<DateTime>> scheduledDatesAsync;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Extract unique dates from entries and sort
    final uniqueDates = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList();
    uniqueDates.sort();

    final grouped = <DateTime, List<TimetableEntry>>{
      for (final date in uniqueDates)
        date: entries
            .where(
              (entry) =>
                  entry.date.year == date.year &&
                  entry.date.month == date.month &&
                  entry.date.day == date.day,
            )
            .toList(),
    };

    // Show shift-plan dates that have no timetable yet
    final shiftPlanDates = scheduledDatesAsync.asData?.value ?? [];

    if (uniqueDates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendarX,
              size: 48,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              'No Timetable Entries',
              style: context.typography.h4.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const Gap(8),
            Text(
              shiftPlanDates.isEmpty
                  ? 'No Shift Plan dates found for this month. Create a Shift Plan first.'
                  : 'Shift Plan has ${shiftPlanDates.length} dates. Use "Plan Timetable" to assign subjects and teachers.',
              style: context.typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: uniqueDates.map((date) {
        final dayEntries = grouped[date] ?? const [];
        final dateString = DateFormat('EEEE, MMM d, yyyy').format(date);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.calendarDays,
                    size: 16,
                    color: colors.primary,
                  ),
                  const Gap(8),
                  Text(dateString, style: context.typography.h4),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${dayEntries.length} period${dayEntries.length == 1 ? '' : 's'}',
                      style: context.typography.bodySmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),
              ...dayEntries.map((entry) => _ScheduleCard(entry: entry)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Timetable Summary ───────────────────────────────────────────────────────

class _TimetableSummary extends StatelessWidget {
  const _TimetableSummary({
    required this.data,
    required this.visibleEntries,
    required this.scheduledDatesAsync,
  });

  final TimetableData data;
  final List<TimetableEntry> visibleEntries;
  final AsyncValue<List<DateTime>> scheduledDatesAsync;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheduledDateCount = scheduledDatesAsync.asData?.value.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Summary', style: context.typography.h4),
          const Gap(16),
          _MetricTile(
            label: 'Planned Dates',
            value: scheduledDateCount.toString(),
            icon: LucideIcons.calendarCheck,
          ),
          const Gap(12),
          _MetricTile(
            label: 'Teachers',
            value: data.teachers.length.toString(),
            icon: LucideIcons.userCheck,
          ),
          const Gap(12),
          _MetricTile(
            label: 'Classes',
            value: data.classes.length.toString(),
            icon: LucideIcons.school,
          ),
          const Gap(12),
          _MetricTile(
            label: 'Visible Periods',
            value: visibleEntries.length.toString(),
            icon: LucideIcons.clock,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary.withValues(alpha: 0.7)),
          const Gap(10),
          Expanded(
            child: Text(
              label,
              style: context.typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: context.typography.bodyLargeSemiBold.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Card ───────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.entry});

  final TimetableEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.period != null) ...[
                  Text(
                    'P${entry.period}',
                    style: context.typography.bodySmallSemiBold.copyWith(
                      color: colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const Gap(4),
                ],
                Text(
                  '${entry.startTime}\n${entry.endTime}',
                  textAlign: TextAlign.center,
                  style: context.typography.bodySmall.copyWith(
                    color: colors.white.withValues(alpha: 0.9),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subject,
                  style: context.typography.bodyLargeSemiBold,
                ),
                const Gap(6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const Gap(6),
                    Text(
                      entry.className,
                      style: context.typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const Gap(12),
                    Icon(
                      LucideIcons.userCheck,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        entry.teacherName,
                        style: context.typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
