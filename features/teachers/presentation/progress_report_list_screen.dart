import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

final progressReportsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final instituteId = ref.watch(selectedInstituteProvider).id;
  final res = await dio.get('/progress-reports', queryParameters: {
    'instituteId': instituteId,
  });
  return res.data as List<dynamic>;
});

class ProgressReportListScreen extends ConsumerWidget {
  const ProgressReportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final reportsAsync = ref.watch(progressReportsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const ABMPageHeader(
            title: 'Progress Reports',
            subtitle: 'View and manage student academic progress records.',
            showBackButton: false,
          ),
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.fileText, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                        const Gap(16),
                        Text(
                          'No reports found',
                          style: typography.h4.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const Gap(16),
                  itemBuilder: (context, index) {
                    final report = reports[index] as Map<String, dynamic>;
                    final student = report['studentId'] as Map<String, dynamic>? ?? {};
                    final status = report['evaluationStatus'] ?? student['evaluationStatus'] ?? 'Pending';
                    final isPassed = status.toString().toLowerCase() == 'passed';
                    
                    return GestureDetector(
                      onTap: () {
                        context.push(RouteNames.editProgressReport, extra: report).then((_) {
                          ref.invalidate(progressReportsProvider);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(LucideIcons.user, color: colors.primary),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['fullName'] ?? 'Unknown Student',
                                    style: typography.bodyLargeSemiBold,
                                  ),
                                  const Gap(4),
                                  Text(
                                    '${student['grade'] ?? 'No Grade'} • ${report['term'] ?? 'No Term'}',
                                    style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPassed ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: typography.bodySmall.copyWith(
                                      color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  '${(report['grades'] as List?)?.length ?? 0} Subjects',
                                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RouteNames.addProgressReport);
        },
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
