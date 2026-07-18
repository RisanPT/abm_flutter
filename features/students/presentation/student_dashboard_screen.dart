import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';
import 'package:abm_madrasa/features/timetable/presentation/planner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _maroon = Color(0xFF5A2A2A);

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key, this.studentId, this.classroom});

  final String? studentId;
  final String? classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final today = instituteToday();
    final provider = studentScheduleProvider(studentId: studentId, classroom: classroom, date: today);
    final async = ref.watch(provider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _maroon,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today’s Timetable', style: typography.h4.copyWith(color: _maroon)),
            Text(DateFormat('EEEE, dd MMMM yyyy').format(today),
                style: typography.bodySmall.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString().replaceFirst('Exception: ', ''))),
        data: (periods) {
          if (periods.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.coffee, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
                  const Gap(12),
                  Text('No classes scheduled today', style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(provider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: periods.length,
              itemBuilder: (_, i) {
                final p = periods[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _maroon.withValues(alpha: 0.1),
                        child: Text('${p.period}', style: typography.bodyMediumSemiBold.copyWith(color: _maroon)),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.subjectName, style: typography.bodyMediumSemiBold),
                            if (p.teacherName != null)
                              Text(p.teacherName!, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        p.startTime.isEmpty ? '' : '${p.startTime} - ${p.endTime}',
                        style: typography.bodySmall.copyWith(color: _maroon),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
