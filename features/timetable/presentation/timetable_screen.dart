import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
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

const _days = <String>[
  'Saturday',
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
];

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  String _selectedClass = 'All Classes';
  String _selectedTeacherId = 'all';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final timetableAsync = ref.watch(timetableDataProvider);
    final userRole = ref.watch(authControllerProvider).asData?.value?.role;
    final canEdit = userRole?.canEditTimetable ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      body: timetableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load timetable: $error')),
        data: (data) {
          final filteredEntries = data.schedule.where((entry) {
            final classMatches =
                _selectedClass == 'All Classes' || entry.className == _selectedClass;
            final teacherMatches = _selectedTeacherId == 'all' ||
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Teacher Timetable',
                                  style: typography.h2.copyWith(color: colors.white),
                                ),
                              ),
                              if (canEdit)
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => context.push(RouteNames.classrooms),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.white.withValues(alpha: 0.15),
                                        foregroundColor: colors.white,
                                      ),
                                      icon: const Icon(LucideIcons.home, size: 18),
                                      label: const Text('Manage Classes'),
                                    ),
                                    const Gap(12),
                                    ElevatedButton.icon(
                                      onPressed: _selectedClass == 'All Classes'
                                          ? null
                                          : () {
                                              final classroom = data.allClassrooms.firstWhere(
                                                (c) => c.name == _selectedClass,
                                              );
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    ClassroomSubjectsDialog(classroom: classroom),
                                              ).then((_) {
                                                ref.invalidate(classroomControllerProvider);
                                                ref.invalidate(timetableDataProvider);
                                              });
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.white.withValues(alpha: 0.2),
                                        foregroundColor: colors.white,
                                      ),
                                      icon: const Icon(LucideIcons.plusCircle, size: 18),
                                      label: const Text('Add Subject'),
                                    ),
                                    const Gap(12),
                                    if (_selectedClass != 'All Classes') ...[
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          final classroom = data.allClassrooms.firstWhere(
                                            (c) => c.name == _selectedClass,
                                          );
                                          showDialog(
                                            context: context,
                                            builder: (context) => ClassroomSubjectsDialog(classroom: classroom),
                                          ).then((_) => ref.invalidate(classroomControllerProvider));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colors.white.withValues(alpha: 0.2),
                                          foregroundColor: colors.white,
                                        ),
                                        icon: const Icon(LucideIcons.listTodo, size: 18),
                                        label: const Text('Define Subjects'),
                                      ),
                                      const Gap(12),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: () => _showAssignmentDialog(context, data),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.white,
                                        foregroundColor: colors.primary,
                                      ),
                                      icon: const Icon(LucideIcons.userPlus, size: 18),
                                      label: const Text('Manage Assignments'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            'Class schedules are driven by teacher assignments and teaching periods.',
                            style: typography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                          const Gap(20),
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
                                Expanded(child: _buildClassSelector(context, data)),
                                const Gap(16),
                                Expanded(child: _buildTeacherSelector(context, data)),
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
                              child: _ScheduleBoard(entries: filteredEntries),
                            ),
                            const Gap(20),
                            Expanded(
                              child: _TimetableSummary(
                                data: data,
                                visibleEntries: filteredEntries,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _TimetableSummary(
                              data: data,
                              visibleEntries: filteredEntries,
                            ),
                            const Gap(16),
                            _ScheduleBoard(entries: filteredEntries),
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

  void _showAssignmentDialog(BuildContext context, TimetableData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TimetableAssignmentDialog(
        data: data,
        initialClassName: _selectedClass == 'All Classes' ? null : _selectedClass,
      ),
    );
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

class _TimetableSummary extends StatelessWidget {
  const _TimetableSummary({
    required this.data,
    required this.visibleEntries,
  });

  final TimetableData data;
  final List<TimetableEntry> visibleEntries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            label: 'Teachers',
            value: data.teachers.length.toString(),
          ),
          const Gap(12),
          _MetricTile(
            label: 'Classes',
            value: data.classes.length.toString(),
          ),
          const Gap(12),
          _MetricTile(
            label: 'Visible periods',
            value: visibleEntries.length.toString(),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

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

class _ScheduleBoard extends StatelessWidget {
  const _ScheduleBoard({required this.entries});

  final List<TimetableEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final grouped = <String, List<TimetableEntry>>{
      for (final day in _days) day: entries.where((entry) => entry.day == day).toList()
    };

    return Column(
      children: _days.map((day) {
        final dayEntries = grouped[day] ?? const [];
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
              Text(day, style: context.typography.h4),
              const Gap(14),
              if (dayEntries.isEmpty)
                Text(
                  'No assigned classes for this day.',
                  style: context.typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                ...dayEntries.map((entry) => _ScheduleCard(entry: entry)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.period != null) ...[
                  Text(
                    'P${entry.period}',
                    style: context.typography.bodySmallSemiBold.copyWith(
                      color: colors.primary,
                      fontSize: 10,
                    ),
                  ),
                  const Gap(2),
                ],
                Text(
                  '${entry.startTime}\n${entry.endTime}',
                  textAlign: TextAlign.center,
                  style: context.typography.bodySmallSemiBold.copyWith(
                    color: colors.textPrimary,
                    height: 1.1,
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
                Text(entry.subject, style: context.typography.bodyLargeSemiBold),
                const Gap(4),
                Text(
                  '${entry.className} • ${entry.teacherName}',
                  style: context.typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (entry.room.isNotEmpty) ...[
                  const Gap(4),
                  Text(
                    'Room: ${entry.room}',
                    style: context.typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
