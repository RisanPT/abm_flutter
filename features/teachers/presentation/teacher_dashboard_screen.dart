import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';
import 'package:abm_madrasa/features/attendance/presentation/class_attendance_sheet.dart';
import 'package:abm_madrasa/features/timetable/domain/planning_models.dart';
import 'package:abm_madrasa/features/timetable/presentation/planner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _maroon = Color(0xFF5A2A2A);
const _maroonDark = Color(0xFF3F1C1C);

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key, this.teacherId});

  /// When null, the backend resolves the logged-in teacher.
  final String? teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _maroon,
          elevation: 0,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('My Classes', style: typography.h4.copyWith(color: _maroon)),
              Text(
                DateFormat('EEEE, dd MMMM').format(instituteToday()),
                style: typography.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _maroon,
                indicatorColor: _maroon,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: typography.bodyMediumSemiBold,
                unselectedLabelStyle: typography.bodyMedium,
                tabs: const [Tab(text: 'Today'), Tab(text: 'Upcoming'), Tab(text: 'Completed')],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _ScheduleList(scope: 'today', teacherId: teacherId),
            _ScheduleList(scope: 'upcoming', teacherId: teacherId),
            _ScheduleList(scope: 'completed', teacherId: teacherId),
          ],
        ),
      ),
    );
  }
}

class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({required this.scope, this.teacherId});
  final String scope;
  final String? teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherScheduleProvider(scope, teacherId: teacherId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _maroon)),
      error: (e, _) => _error(context, e.toString().replaceFirst('Exception: ', '')),
      data: (classes) {
        if (classes.isEmpty) return _empty(context, scope);

        final showHero = scope == 'today';
        return RefreshIndicator(
          color: _maroon,
          onRefresh: () async => ref.invalidate(teacherScheduleProvider(scope, teacherId: teacherId)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: classes.length + (showHero ? 1 : 0),
            itemBuilder: (_, i) {
              if (showHero && i == 0) return _TodayHero(classes: classes);
              final c = classes[showHero ? i - 1 : i];
              return _ClassCard(
                c: c,
                onRefresh: () => ref.invalidate(teacherScheduleProvider(scope, teacherId: teacherId)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _error(BuildContext context, String msg) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.wifiOff, size: 44, color: colors.textSecondary.withValues(alpha: 0.4)),
            const Gap(12),
            Text(msg, textAlign: TextAlign.center, style: context.typography.bodyMedium.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, String scope) {
    final colors = context.colors;
    const messages = {
      'today': 'No classes scheduled today.\nEnjoy your day!',
      'upcoming': 'No upcoming classes yet.',
      'completed': 'No completed classes to show.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: _maroon.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: Icon(LucideIcons.calendarCheck, size: 40, color: _maroon.withValues(alpha: 0.55)),
            ),
            const Gap(16),
            Text(
              messages[scope] ?? 'Nothing here',
              textAlign: TextAlign.center,
              style: context.typography.bodyMedium.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maroon hero summarising the teacher's day: total classes, how many still
/// need attendance, and how many are done.
class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.classes});
  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final total = classes.length;
    final marked = classes.where((c) => c.alreadyMarked).length;
    final pending = classes.where((c) => c.attendanceEnabled && !c.alreadyMarked).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_maroon, _maroonDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _maroon.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sun, color: Color(0xFFF4D06F), size: 20),
              const Gap(8),
              Text('Today’s Overview',
                  style: typography.bodyMediumSemiBold.copyWith(color: Colors.white)),
              const Spacer(),
              Text(DateFormat('dd MMM').format(instituteToday()),
                  style: typography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              _HeroStat(value: total, label: 'Classes', icon: LucideIcons.bookOpen),
              _heroDivider(),
              _HeroStat(value: pending, label: 'To mark', icon: LucideIcons.clock, accent: const Color(0xFFF4D06F)),
              _heroDivider(),
              _HeroStat(value: marked, label: 'Done', icon: LucideIcons.checkCircle2, accent: const Color(0xFF7BD88F)),
            ],
          ),
          if (pending == 0 && total > 0) ...[
            const Gap(14),
            Row(
              children: [
                const Icon(LucideIcons.partyPopper, size: 15, color: Color(0xFF7BD88F)),
                const Gap(6),
                Text('All attendance marked for today',
                    style: typography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.18));
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label, required this.icon, this.accent});
  final int value;
  final String label;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final color = accent ?? Colors.white;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.9)),
          const Gap(6),
          Text('$value', style: typography.h3.copyWith(color: color, fontWeight: FontWeight.w700)),
          const Gap(2),
          Text(label, style: typography.caption.copyWith(color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.c, required this.onRefresh});
  final TeacherClass c;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMobile = context.isMobile;

    final marked = c.alreadyMarked;
    final canMark = c.attendanceEnabled && !marked;
    final accent = marked
        ? colors.green
        : canMark
            ? _maroon
            : colors.textSecondary;

    final hasTime = c.startTime.isNotEmpty;

    final timeBlock = Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasTime ? c.startTime : 'P${c.period}',
            style: typography.bodyMediumSemiBold.copyWith(color: accent),
          ),
          const Gap(2),
          Text(
            hasTime ? c.endTime : 'Period',
            style: typography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );

    final subtitleParts = [
      c.classroomName,
      'Period ${c.period}',
      if (c.room.isNotEmpty) c.room,
    ].where((s) => s.isNotEmpty).join('  •  ');

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.subjectName.isEmpty ? 'Class' : c.subjectName,
          style: typography.bodyLargeSemiBold.copyWith(color: const Color(0xFF1F2937)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(3),
        Text(
          subtitleParts,
          style: typography.bodySmall.copyWith(color: colors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(2),
        Text(
          DateFormat('EEE, dd MMM').format(c.date),
          style: typography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.85)),
        ),
      ],
    );

    // Status pill shown for marked / locked (the CTA replaces it when actionable).
    Widget? statusPill;
    if (marked) {
      statusPill = _StatusPill(color: colors.green, icon: LucideIcons.checkCircle2, label: 'Marked');
    } else if (!canMark) {
      statusPill = _StatusPill(color: colors.textSecondary, icon: LucideIcons.lock, label: 'Locked');
    }

    final markButton = SizedBox(
      height: 46,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => showClassAttendanceSheet(
          context,
          scheduledClassId: c.id,
          classroomName: c.classroomName,
          subjectName: c.subjectName,
          period: c.period,
          shift: c.shift,
          onSaved: onRefresh,
        ),
        icon: const Icon(LucideIcons.clipboardCheck, size: 18),
        label: const Text('Mark Attendance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _maroon,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: typography.bodyMediumSemiBold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accent),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          timeBlock,
                          const Gap(14),
                          Expanded(child: info),
                          if (statusPill != null) ...[const Gap(8), statusPill],
                          // Desktop keeps the action inline to avoid a stretched button.
                          if (canMark && !isMobile) ...[
                            const Gap(12),
                            SizedBox(width: 190, child: markButton),
                          ],
                        ],
                      ),
                      // Mobile: full-width tap target below the details.
                      if (canMark && isMobile) ...[
                        const Gap(14),
                        markButton,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.icon, required this.label});
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(5),
          Text(label, style: context.typography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
