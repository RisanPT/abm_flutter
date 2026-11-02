import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/exams/data/exam_repository.dart';
import 'package:abm_madrasa/features/exams/presentation/report_card_pdf.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/teachers/domain/teacher_model.dart';
import 'package:abm_madrasa/features/teachers/presentation/teacher_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

Color gradeColor(BuildContext context, String g) {
  final c = context.colors;
  if (g == 'A+' || g == 'A') return c.green;
  if (g == 'B' || g == 'C') return c.primary;
  if (g == 'D') return c.warning;
  return c.red;
}

const List<String> kStandardExamHeadings = [
  'Class Test 1',
  'Half-Yearly Exams',
  'Class Test 2',
  'Final Exams',
];

Color getExamGroupColor(String groupName) {
  final lower = groupName.toLowerCase();
  if (lower.contains('test 1')) return const Color(0xFF2563EB); // Royal Blue
  if (lower.contains('half-yearly') || lower.contains('mid-term') || lower.contains('term 1')) {
    return const Color(0xFF059669); // Emerald
  }
  if (lower.contains('test 2')) return const Color(0xFF7C3AED); // Violet
  if (lower.contains('final') || lower.contains('annual') || lower.contains('term 2')) {
    return const Color(0xFFD97706); // Amber
  }
  return const Color(0xFF0D9488); // Teal
}

IconData getExamGroupIcon(String groupName) {
  final lower = groupName.toLowerCase();
  if (lower.contains('test 1')) return LucideIcons.fileCheck2;
  if (lower.contains('half-yearly') || lower.contains('mid-term')) return LucideIcons.award;
  if (lower.contains('test 2')) return LucideIcons.fileText;
  if (lower.contains('final') || lower.contains('annual')) return LucideIcons.trophy;
  return LucideIcons.bookOpen;
}

class ExamRosterQuery {
  const ExamRosterQuery({required this.classroom, this.shift});
  final String classroom;
  final String? shift;

  @override
  bool operator ==(Object other) =>
      other is ExamRosterQuery && classroom == other.classroom && shift == other.shift;

  @override
  int get hashCode => Object.hash(classroom, shift);
}

final _examRosterProvider =
    FutureProvider.autoDispose.family<List<StudentModel>, ExamRosterQuery>((ref, q) {
  final inst = ref.watch(selectedInstituteProvider).id;
  return ref.read(studentRepositoryProvider).getStudents(
        instituteId: inst,
        classroom: q.classroom,
        shift: (q.shift == null || q.shift == 'All' || q.shift!.isEmpty) ? null : q.shift,
      );
});

class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user?.role == AppRoles.student) return const _StudentResultsView();
    return const _StaffExamsView();
  }
}

// ─── Student Results View (Hierarchical) ────────────────────────────────────

class _StudentResultsView extends ConsumerWidget {
  const _StudentResultsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final async = ref.watch(myResultsProvider);
    final user = ref.watch(authControllerProvider).value;
    final studentName = user?.username ?? 'Student';

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'My Results',
            subtitle: 'Academic progress and report cards',
            height: context.isMobile ? 160 : 180,
          ),
          Expanded(
            child: async.when(
              data: (results) {
                if (results.isEmpty) {
                  return const AbmEmptyState(
                    icon: LucideIcons.award,
                    title: 'No results yet',
                    message: 'Your exam results will appear here once published by your teachers.',
                  );
                }

                // Overall calculations
                final validResults = results.where((r) => r.maxTotal > 0).toList();
                final overallPct = validResults.isNotEmpty
                    ? (validResults.map((r) => r.percentage).reduce((a, b) => a + b) / validResults.length)
                    : 0.0;

                // Group student results hierarchically by exam name / series
                final grouped = <String, List<ExamResult>>{};
                for (final r in results) {
                  final rawName = r.exam?.name.trim() ?? 'General Exams';
                  String header = rawName;
                  for (final h in kStandardExamHeadings) {
                    if (rawName.toLowerCase().startsWith(h.toLowerCase())) {
                      header = h;
                      break;
                    }
                  }
                  grouped.putIfAbsent(header, () => []).add(r);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Performance Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 28),
                          ),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: typography.bodyLargeSemiBold.copyWith(color: Colors.white),
                                ),
                                const Gap(2),
                                Text(
                                  '${results.length} evaluations published across ${grouped.length} exam cycles',
                                  style: typography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${overallPct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Overall Avg',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(20),

                    // Hierarchical Exam Sections
                    ...grouped.entries.map((entry) {
                      final headerTitle = entry.key;
                      final headerResults = entry.value;
                      final themeColor = getExamGroupColor(headerTitle);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const Gap(8),
                              Icon(getExamGroupIcon(headerTitle), size: 16, color: themeColor),
                              const Gap(6),
                              Text(
                                headerTitle,
                                style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${headerResults.length} Result${headerResults.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          for (final r in headerResults) ...[
                            _StudentResultHierarchicalCard(
                              result: r,
                              onDownload: r.exam == null
                                  ? null
                                  : () => printReportCard(
                                        exam: r.exam!,
                                        result: r,
                                        studentName: studentName,
                                      ),
                            ),
                            const Gap(12),
                          ],
                          const Gap(12),
                        ],
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(myResultsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentResultHierarchicalCard extends StatelessWidget {
  const _StudentResultHierarchicalCard({required this.result, this.onDownload});

  final ExamResult result;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final exam = result.exam;
    final maxBySubject = {for (final s in exam?.subjects ?? const <ExamSubject>[]) s.name: s.maxMarks};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam?.name ?? 'Exam Evaluation', style: t.bodyLargeSemiBold),
                    const Gap(2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (result.classroom.isNotEmpty || (exam != null && exam.classroom.isNotEmpty))
                          Text(
                            result.classroom.isNotEmpty ? result.classroom : exam!.classroom,
                            style: t.bodySmall.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        if (result.shift.isNotEmpty || (exam != null && exam.shift.isNotEmpty))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (result.shift == 'Shift-2' || exam?.shift == 'Shift-2')
                                  ? const Color(0xFFFAF5FF)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (result.shift == 'Shift-2' || exam?.shift == 'Shift-2')
                                    ? const Color(0xFFE9D5FF)
                                    : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              result.shift.isNotEmpty ? result.shift : exam!.shift,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: (result.shift == 'Shift-2' || exam?.shift == 'Shift-2')
                                    ? const Color(0xFF7E22CE)
                                    : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        if (exam?.term.isNotEmpty == true)
                          Text('· ${exam!.term}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              AbmStatusPill(label: result.grade, color: gradeColor(context, result.grade)),
            ],
          ),
          const Gap(14),

          // Total & Percentage row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10)),
                      Text('${result.total} / ${result.maxTotal}', style: t.bodyMediumSemiBold),
                    ],
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Percentage', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10)),
                      Text('${result.percentage}%', style: t.bodyMediumSemiBold),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Subject-wise Marks Breakdown
          if (result.marks.isNotEmpty) ...[
            const Gap(14),
            Text('Subject Breakdown', style: t.bodySmall.copyWith(fontWeight: FontWeight.bold, color: colors.textSecondary)),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: result.marks.map((m) {
                final max = maxBySubject[m.subject] ?? 100;
                final pct = max > 0 ? (m.score / max) * 100 : 0;
                final isPassing = pct >= 40;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPassing ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPassing ? colors.border : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.subject,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const Gap(6),
                      Text(
                        '${m.score}/$max',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPassing ? colors.primary : colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          if (result.remarks.isNotEmpty) ...[
            const Gap(12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.messageSquare, size: 14, color: Color(0xFFB45309)),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      result.remarks,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Gap(14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(LucideIcons.download, size: 15),
              label: const Text('Download Official Report Card'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Staff Exams View (Hierarchical Exams Structure) ─────────────────────────

class _StaffExamsView extends ConsumerStatefulWidget {
  const _StaffExamsView();

  @override
  ConsumerState<_StaffExamsView> createState() => _StaffExamsViewState();
}

class _StaffExamsViewState extends ConsumerState<_StaffExamsView> {
  final ScrollController _scrollController = ScrollController();
  String _class = 'All';
  String _shift = 'All';
  String _selectedHeaderFilter = 'All';
  String _searchQuery = '';
  final Set<String> _collapsedGroups = <String>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleGroupCollapse(String groupName) {
    setState(() {
      if (_collapsedGroups.contains(groupName)) {
        _collapsedGroups.remove(groupName);
      } else {
        _collapsedGroups.add(groupName);
      }
    });
  }

  void _expandAll(List<String> groups) {
    setState(() => _collapsedGroups.clear());
  }

  void _collapseAll(List<String> groups) {
    setState(() => _collapsedGroups.addAll(groups));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final classesAsync = ref.watch(classroomControllerProvider);
    final classroomOptions =
        classesAsync.maybeWhen(data: (c) => ['All', ...c.map((e) => e.name)], orElse: () => <String>['All']);
    final examsAsync = ref.watch(examsListProvider(_class));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Exams & Results',
            subtitle: 'Hierarchical Exam Management & Performance Center',
            showBackButton: false,
            compact: true,
            actions: [
              FilledButton.icon(
                onPressed: () => _createExam(),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('New Exam'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Gap(8),
              IconButton(
                onPressed: () {
                  ref.invalidate(examsListProvider);
                  ref.invalidate(examsPageProvider);
                },
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Exams',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Expanded(
            child: examsAsync.when(
              data: (allExams) {
                // Filter exams by Shift and Search Query
                final filtered = allExams.where((exam) {
                  final shiftMatch = _shift == 'All' || exam.shift == _shift || exam.shift == 'All';
                  if (!shiftMatch) return false;

                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final subjectsStr = exam.subjects.map((s) => '${s.name} ${s.teacher}').join(' ');
                  return exam.name.toLowerCase().contains(q) ||
                      exam.classroom.toLowerCase().contains(q) ||
                      exam.shift.toLowerCase().contains(q) ||
                      exam.term.toLowerCase().contains(q) ||
                      exam.assignedTeacher.toLowerCase().contains(q) ||
                      subjectsStr.toLowerCase().contains(q);
                }).toList();

                // Group hierarchically under distinct headers
                final hierarchicalGroups = <String, List<Exam>>{};

                // First initialize standard headers in clear hierarchical order
                for (final stdHeader in kStandardExamHeadings) {
                  hierarchicalGroups[stdHeader] = [];
                }

                for (final e in filtered) {
                  final rawName = e.name.trim();
                  String matchedHeader = '';
                  for (final stdHeader in kStandardExamHeadings) {
                    if (rawName.toLowerCase().startsWith(stdHeader.toLowerCase())) {
                      matchedHeader = stdHeader;
                      break;
                    }
                  }
                  if (matchedHeader.isNotEmpty) {
                    hierarchicalGroups[matchedHeader]!.add(e);
                  } else {
                    // Custom exam group title
                    hierarchicalGroups.putIfAbsent(rawName, () => []).add(e);
                  }
                }

                // Filter out empty standard headers if not present and no filter applied,
                // but keep those that have items or match filter
                final activeGroups = <String, List<Exam>>{};
                for (final entry in hierarchicalGroups.entries) {
                  if (_selectedHeaderFilter != 'All' && entry.key != _selectedHeaderFilter) {
                    continue;
                  }
                  if (entry.value.isNotEmpty || _selectedHeaderFilter == entry.key) {
                    activeGroups[entry.key] = entry.value;
                  }
                }

                // KPI Calculations across all exams
                final distinctClasses = <String>{};
                int totalSubjectsCount = 0;
                for (final e in filtered) {
                  if (e.classroom.isNotEmpty) distinctClasses.add(e.classroom);
                  totalSubjectsCount += e.subjects.length;
                }

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                    children: [
                      // KPI Stat Cards Strip
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          final kpis = [
                            _ExamKpiCard(
                              title: 'Exam Categories',
                              value: '${activeGroups.length}',
                              subtext: 'Organized hierarchically',
                              icon: LucideIcons.layers,
                              color: const Color(0xFF2563EB),
                              badge: 'Hierarchy',
                            ),
                            _ExamKpiCard(
                              title: 'Class Sections',
                              value: '${distinctClasses.length}',
                              subtext: '${filtered.length} total exam schedules',
                              icon: LucideIcons.graduationCap,
                              color: const Color(0xFF059669),
                              badge: 'Active Classes',
                            ),
                            _ExamKpiCard(
                              title: 'Curriculum Subjects',
                              value: '$totalSubjectsCount',
                              subtext: 'Evaluated across sections',
                              icon: LucideIcons.bookOpen,
                              color: const Color(0xFFD97706),
                              badge: 'Curriculum',
                            ),
                          ];

                          if (isWide) {
                            return Row(
                              children: [
                                for (int i = 0; i < kpis.length; i++) ...[
                                  if (i > 0) const Gap(12),
                                  Expanded(child: kpis[i]),
                                ],
                              ],
                            );
                          }
                          return Column(
                            children: [
                              for (int i = 0; i < kpis.length; i++) ...[
                                if (i > 0) const Gap(8),
                                kpis[i],
                              ],
                            ],
                          );
                        },
                      ),

                      const Gap(14),

                      // Search, Header Navigation Chips & Filters
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search bar
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                    decoration: InputDecoration(
                                      hintText: 'Search by exam, class, subject, or assigned teacher...',
                                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty || _class != 'All' || _shift != 'All' || _selectedHeaderFilter != 'All') ...[
                                  const Gap(8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _class = 'All';
                                        _shift = 'All';
                                        _selectedHeaderFilter = 'All';
                                      });
                                    },
                                    icon: const Icon(LucideIcons.rotateCcw, size: 14),
                                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),

                            const Gap(12),

                            // Hierarchy Header Navigation Pills (e.g. Class Test 1, Half-Yearly, Class Test 2, Final Exams)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('All Exam Groups', style: TextStyle(fontSize: 11)),
                                    selected: _selectedHeaderFilter == 'All',
                                    onSelected: (sel) {
                                      if (sel) setState(() => _selectedHeaderFilter = 'All');
                                    },
                                    selectedColor: colors.primary.withValues(alpha: 0.15),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  for (final h in kStandardExamHeadings) ...[
                                    const Gap(6),
                                    ChoiceChip(
                                      avatar: Icon(getExamGroupIcon(h), size: 13, color: getExamGroupColor(h)),
                                      label: Text(h, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      selected: _selectedHeaderFilter == h,
                                      onSelected: (sel) {
                                        setState(() => _selectedHeaderFilter = sel ? h : 'All');
                                      },
                                      selectedColor: getExamGroupColor(h).withValues(alpha: 0.15),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const Gap(10),

                            // Class and Shift filter row
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _class,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Class / Grade',
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(LucideIcons.graduationCap, size: 16),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                    ),
                                    items: classroomOptions
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _class = val);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _shift,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Shift',
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(LucideIcons.clock, size: 16),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'All', child: Text('All Shifts', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Shift-1', child: Text('Shift-1', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Shift-2', child: Text('Shift-2', style: TextStyle(fontSize: 12))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _shift = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Gap(16),

                      // Section Title & Global Expand/Collapse toolbar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeGroups.isEmpty
                                    ? 'No exam groups'
                                    : 'Exam Hierarchy (${activeGroups.length} Categories)',
                                style: typography.bodyMediumSemiBold,
                              ),
                            ],
                          ),
                          if (activeGroups.isNotEmpty)
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _expandAll(activeGroups.keys.toList()),
                                  icon: const Icon(LucideIcons.chevronsDown, size: 14),
                                  label: const Text('Expand All', style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                                TextButton.icon(
                                  onPressed: () => _collapseAll(activeGroups.keys.toList()),
                                  icon: const Icon(LucideIcons.chevronsUp, size: 14),
                                  label: const Text('Collapse All', style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                              ],
                            ),
                        ],
                      ),

                      const Gap(10),

                      if (activeGroups.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.award, size: 36, color: colors.primary),
                              ),
                              const Gap(12),
                              Text('No exams scheduled', style: typography.bodyLargeSemiBold),
                              const Gap(6),
                              Text(
                                'Tap "New Exam" to structure exams under Class Test 1, Half-Yearly, etc.',
                                style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const Gap(16),
                              FilledButton.icon(
                                onPressed: () => _createExam(),
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Create Exam'),
                                style: FilledButton.styleFrom(backgroundColor: colors.primary),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // RENDER HIERARCHICAL EXAM GROUPS
                        for (final entry in activeGroups.entries) ...[
                          _HierarchicalExamGroupSection(
                            groupName: entry.key,
                            exams: entry.value,
                            isCollapsed: _collapsedGroups.contains(entry.key),
                            onToggleCollapse: () => _toggleGroupCollapse(entry.key),
                            onAddClassToGroup: () => _createExam(prefilledExamName: entry.key),
                            onOpenExam: (exam) => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => _ExamMarksScreen(exam: exam)),
                            ),
                            onDeleteExam: (exam) => _deleteExam(exam),
                          ),
                          const Gap(16),
                        ],
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(examsListProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createExam(),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Create exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _deleteExam(Exam exam) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmActionDialog(
      context,
      title: 'Delete exam',
      message: 'Delete "${exam.name}" (${exam.classroom}) and all student marks?',
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    try {
      await ref.read(examRepositoryProvider).deleteExam(exam.id);
      ref.invalidate(examsListProvider);
      ref.invalidate(examsPageProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Exam deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _createExam({String? prefilledExamName}) async {
    final classrooms = ref.read(classroomControllerProvider).maybeWhen(data: (c) => c, orElse: () => <ClassroomModel>[]);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateExamSheet(
        classrooms: classrooms,
        defaultExamName: prefilledExamName,
      ),
    );
    if (ok == true) {
      ref.invalidate(examsListProvider);
      ref.invalidate(examsPageProvider);
    }
  }
}

// ─── Hierarchical Exam Group Section Component ───────────────────────────────

class _HierarchicalExamGroupSection extends StatelessWidget {
  const _HierarchicalExamGroupSection({
    required this.groupName,
    required this.exams,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onAddClassToGroup,
    required this.onOpenExam,
    required this.onDeleteExam,
  });

  final String groupName;
  final List<Exam> exams;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAddClassToGroup;
  final ValueChanged<Exam> onOpenExam;
  final ValueChanged<Exam> onDeleteExam;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final themeColor = getExamGroupColor(groupName);
    final groupIcon = getExamGroupIcon(groupName);

    // Summary calculations
    final distinctClasses = exams.map((e) => e.classroom).toSet();
    int totalSubjects = 0;
    for (final e in exams) {
      totalSubjects += e.subjects.length;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distinct Main Exam Group Header Banner
          InkWell(
            onTap: onToggleCollapse,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(18),
              bottom: isCollapsed ? const Radius.circular(18) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(18),
                  bottom: isCollapsed ? const Radius.circular(18) : Radius.zero,
                ),
                border: Border(
                  bottom: isCollapsed ? BorderSide.none : BorderSide(color: colors.border),
                  left: BorderSide(color: themeColor, width: 5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(groupIcon, color: themeColor, size: 20),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              groupName,
                              style: typography.bodyLargeSemiBold.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${exams.length} Class${exams.length == 1 ? '' : 'es'}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeColor),
                              ),
                            ),
                          ],
                        ),
                        const Gap(3),
                        Text(
                          exams.isEmpty
                              ? 'No classes enrolled yet'
                              : '${distinctClasses.join(', ')} · $totalSubjects Subjects Tested',
                          style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onAddClassToGroup,
                    icon: Icon(LucideIcons.plus, size: 18, color: themeColor),
                    tooltip: 'Add Class to $groupName',
                    visualDensity: VisualDensity.compact,
                  ),
                  const Gap(4),
                  Icon(
                    isCollapsed ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Sub-Items (Classes, Shifts, Subjects & Respective Assigned Teachers)
          if (!isCollapsed) ...[
            if (exams.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'No classes added under $groupName yet.',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                      const Gap(8),
                      TextButton.icon(
                        onPressed: onAddClassToGroup,
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: Text('Enroll a class for $groupName'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                itemCount: exams.length,
                separatorBuilder: (_, _) => const Gap(10),
                itemBuilder: (_, i) {
                  final exam = exams[i];
                  return _ExamClassSubItemCard(
                    exam: exam,
                    themeColor: themeColor,
                    onOpen: () => onOpenExam(exam),
                    onDelete: () => onDeleteExam(exam),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-Item Card for Class, Shift, Subjects & Assigned Teacher ─────────────

class _ExamClassSubItemCard extends StatelessWidget {
  const _ExamClassSubItemCard({
    required this.exam,
    required this.themeColor,
    required this.onOpen,
    required this.onDelete,
  });

  final Exam exam;
  final Color themeColor;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Class, Shift, Assigned Teacher & Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(LucideIcons.graduationCap, size: 18, color: colors.primary),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                exam.classroom.isEmpty ? 'All Classes' : exam.classroom,
                                style: typography.bodyMediumSemiBold.copyWith(fontSize: 14),
                              ),
                              const Gap(8),
                              // Shift Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: exam.shift == 'Shift-2'
                                      ? const Color(0xFFFAF5FF)
                                      : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: exam.shift == 'Shift-2'
                                        ? const Color(0xFFE9D5FF)
                                        : const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Text(
                                  exam.shift.isEmpty ? 'Shift-1' : exam.shift,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: exam.shift == 'Shift-2'
                                        ? const Color(0xFF7E22CE)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                              if (exam.term.isNotEmpty) ...[
                                const Gap(6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    exam.term,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Gap(4),

                          // Respective Assigned Teacher
                          Row(
                            children: [
                              Icon(LucideIcons.userCheck, size: 12, color: colors.textSecondary),
                              const Gap(5),
                              Text(
                                exam.assignedTeacher.isNotEmpty
                                    ? 'Assigned Teacher: ${exam.assignedTeacher}'
                                    : 'Teacher: Not explicitly assigned',
                                style: typography.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: exam.assignedTeacher.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                  color: exam.assignedTeacher.isNotEmpty ? colors.primary : colors.textSecondary,
                                ),
                              ),
                              if (exam.date != null) ...[
                                const Gap(10),
                                Icon(LucideIcons.calendar, size: 12, color: colors.textSecondary),
                                const Gap(4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(exam.date!),
                                  style: typography.bodySmall.copyWith(fontSize: 11, color: colors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onOpen,
                      icon: const Icon(LucideIcons.pencil, size: 13),
                      label: const Text('Enter Marks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const Gap(2),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, size: 16, color: colors.red),
                      tooltip: 'Delete Class Exam',
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

                // Subjects Breakdown Sub-Items
                if (exam.subjects.isNotEmpty) ...[
                  const Gap(10),
                  const Divider(height: 1),
                  const Gap(8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Subjects (${exam.subjects.length}):',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: colors.textSecondary),
                      ),
                      ...exam.subjects.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                              const Gap(4),
                              Text('(${s.maxMarks})', style: TextStyle(fontSize: 9.5, color: colors.textSecondary)),
                              if (s.teacher.isNotEmpty) ...[
                                const Gap(4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    s.teacher,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.primary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── KPI Card Widget ─────────────────────────────────────────────────────────

class _ExamKpiCard extends StatelessWidget {
  const _ExamKpiCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.badge,
  });

  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(value, style: typography.h2.copyWith(fontWeight: FontWeight.bold)),
          const Gap(2),
          Text(title, style: typography.bodyMediumSemiBold),
          Text(subtext, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Create Exam Sheet (Supports Hierarchy & Assigned Teachers) ──────────────

class _CreateExamSheet extends ConsumerStatefulWidget {
  const _CreateExamSheet({required this.classrooms, this.defaultExamName});

  final List<ClassroomModel> classrooms;
  final String? defaultExamName;

  @override
  ConsumerState<_CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends ConsumerState<_CreateExamSheet> {
  late final TextEditingController _name;
  final _term = TextEditingController();
  String? _class;
  String _shift = 'Shift-1';
  String? _assignedTeacher;
  final DateTime _date = DateTime.now();
  final List<({TextEditingController name, TextEditingController max, TextEditingController teacher})> _subjects = [
    (name: TextEditingController(), max: TextEditingController(text: '100'), teacher: TextEditingController()),
  ];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.defaultExamName ?? 'Class Test 1');
  }

  ClassroomModel? get _selectedClassroom =>
      widget.classrooms.where((c) => c.name == _class).firstOrNull;

  @override
  void dispose() {
    _name.dispose();
    _term.dispose();
    for (final s in _subjects) {
      s.name.dispose();
      s.max.dispose();
      s.teacher.dispose();
    }
    super.dispose();
  }

  void _onClassChanged(String? v) {
    setState(() {
      _class = v;
      if (v == null) return;
      final cr = widget.classrooms.where((c) => c.name == v).firstOrNull;
      if (cr != null) {
        if (cr.shift.isNotEmpty) {
          _shift = cr.shift;
        }
        if (cr.subjects.isNotEmpty) {
          final isSingleEmpty = _subjects.length == 1 && _subjects.first.name.text.trim().isEmpty;
          if (isSingleEmpty) {
            _populateSubjects(cr.subjects);
          }
        }
      }
    });
  }

  void _populateSubjects(List<String> subjects) {
    for (final s in _subjects) {
      s.name.dispose();
      s.max.dispose();
      s.teacher.dispose();
    }
    _subjects.clear();
    for (final subj in subjects) {
      _subjects.add((
        name: TextEditingController(text: subj),
        max: TextEditingController(text: '100'),
        teacher: TextEditingController(text: _assignedTeacher ?? ''),
      ));
    }
  }

  void _addSubjectIfNotExists(String subj) {
    final exists = _subjects.any((s) => s.name.text.trim().toLowerCase() == subj.trim().toLowerCase());
    if (exists) return;
    if (_subjects.length == 1 && _subjects.first.name.text.trim().isEmpty) {
      _subjects.first.name.text = subj;
      _subjects.first.teacher.text = _assignedTeacher ?? '';
    } else {
      _subjects.add((
        name: TextEditingController(text: subj),
        max: TextEditingController(text: '100'),
        teacher: TextEditingController(text: _assignedTeacher ?? ''),
      ));
    }
    setState(() {});
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter an exam name.')));
      return;
    }
    if (_class == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Choose a class.')));
      return;
    }
    final subjects = _subjects
        .where((s) => s.name.text.trim().isNotEmpty)
        .map((s) => ExamSubject(
              name: s.name.text.trim(),
              maxMarks: int.tryParse(s.max.text.trim()) ?? 100,
              teacher: s.teacher.text.trim(),
            ))
        .toList();
    if (subjects.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Add at least one subject.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(examRepositoryProvider).createExam(
            name: _name.text.trim(),
            classroom: _class!,
            shift: _shift,
            term: _term.text.trim(),
            date: _date,
            subjects: subjects,
            assignedTeacher: _assignedTeacher ?? '',
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cr = _selectedClassroom;
    final curriculumSubjects = cr?.subjects ?? const <String>[];
    final teachersAsync = ref.watch(teacherListProvider(''));
    final teacherList = teachersAsync.maybeWhen(data: (t) => t, orElse: () => <TeacherModel>[]);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Gap(14),
            Row(
              children: [
                Icon(LucideIcons.award, color: colors.primary, size: 22),
                const Gap(8),
                Text('Create Hierarchical Exam', style: context.typography.h4),
              ],
            ),
            const Gap(16),

            // Exam Heading Preset Selector
            Text('Exam Heading / Hierarchy Level', style: context.typography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            const Gap(6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kStandardExamHeadings.map((preset) {
                final isSelected = _name.text.trim() == preset;
                return ChoiceChip(
                  label: Text(preset, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _name.text = preset);
                  },
                  selectedColor: getExamGroupColor(preset).withValues(alpha: 0.18),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const Gap(10),

            ABMTextField(
              label: 'Exam Name / Heading',
              hint: 'e.g. Class Test 1, Half-Yearly Exams, Class Test 2, Final Exams',
              controller: _name,
            ),
            const Gap(12),

            // Class and Shift Selection
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _class,
                    decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                    items: widget.classrooms.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: _onClassChanged,
                  ),
                ),
                const Gap(10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _shift,
                    decoration: const InputDecoration(
                      labelText: 'Shift',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.clock, size: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Shift-1', child: Text('Shift-1')),
                      DropdownMenuItem(value: 'Shift-2', child: Text('Shift-2')),
                      DropdownMenuItem(value: 'All', child: Text('All Shifts')),
                    ],
                    onChanged: (v) => setState(() => _shift = v ?? 'Shift-1'),
                  ),
                ),
              ],
            ),
            const Gap(12),

            // Assigned Teacher Selector
            DropdownButtonFormField<String>(
              initialValue: _assignedTeacher,
              decoration: const InputDecoration(
                labelText: 'Respective Assigned Teacher',
                hintText: 'Select in-charge teacher for this exam class',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.userCheck, size: 18),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('No teacher assigned')),
                ...teacherList.map((t) => DropdownMenuItem(
                      value: t.fullName,
                      child: Text('${t.title.isNotEmpty ? '${t.title} ' : ''}${t.fullName}'),
                    )),
              ],
              onChanged: (val) {
                setState(() {
                  _assignedTeacher = val;
                  if (val != null && val.isNotEmpty) {
                    for (final s in _subjects) {
                      if (s.teacher.text.trim().isEmpty) s.teacher.text = val;
                    }
                  }
                });
              },
            ),
            const Gap(12),

            // Curriculum subjects quick chips
            if (curriculumSubjects.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Class subjects:', style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
                  ...curriculumSubjects.map((s) {
                    final isIncluded = _subjects.any((sub) => sub.name.text.trim().toLowerCase() == s.toLowerCase());
                    return ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(s, style: TextStyle(fontSize: 11, color: isIncluded ? colors.primary : colors.textPrimary)),
                      avatar: Icon(
                        isIncluded ? LucideIcons.check : LucideIcons.plus,
                        size: 12,
                        color: isIncluded ? colors.primary : colors.textSecondary,
                      ),
                      onPressed: () => _addSubjectIfNotExists(s),
                    );
                  }),
                  TextButton(
                    onPressed: () => setState(() => _populateSubjects(curriculumSubjects)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 6)),
                    child: const Text('Add all', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const Gap(10),
            ],

            ABMTextField(label: 'Term / Academic Year (optional)', hint: 'e.g. 2026', controller: _term),
            const Gap(16),

            // Subjects list
            Row(
              children: [
                Text('Subjects & Respective Teachers', style: context.typography.bodyMediumSemiBold),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _subjects.add((
                        name: TextEditingController(),
                        max: TextEditingController(text: '100'),
                        teacher: TextEditingController(text: _assignedTeacher ?? ''),
                      ))),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add subject'),
                ),
              ],
            ),
            const Gap(6),
            for (var i = 0; i < _subjects.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ABMTextField(
                        label: 'Subject',
                        hint: 'e.g. Quran',
                        controller: _subjects[i].name,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      flex: 1,
                      child: ABMTextField(
                        label: 'Max',
                        hint: '100',
                        controller: _subjects[i].max,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      flex: 3,
                      child: ABMTextField(
                        label: 'Subject Teacher',
                        hint: 'e.g. Ustadh Ahmed',
                        controller: _subjects[i].teacher,
                      ),
                    ),
                    if (_subjects.length > 1)
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: colors.red),
                        onPressed: () => setState(() {
                          _subjects[i].name.dispose();
                          _subjects[i].max.dispose();
                          _subjects[i].teacher.dispose();
                          _subjects.removeAt(i);
                        }),
                      ),
                  ],
                ),
              ),

            const Gap(18),
            ABMButton(text: 'Save and Schedule Exam', isLoading: _saving, onPressed: _save),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}

// ─── ADVANCED EXAM RESULT SCREEN & PERFORMANCE CENTER ────────────────────────

enum _ResultViewMode { cards, matrix, analytics }

class _ExamMarksScreen extends ConsumerStatefulWidget {
  const _ExamMarksScreen({required this.exam});

  final Exam exam;

  @override
  ConsumerState<_ExamMarksScreen> createState() => _ExamMarksScreenState();
}

class _ExamMarksScreenState extends ConsumerState<_ExamMarksScreen> {
  late String _selectedShift;
  String _search = '';
  String _gradeFilter = 'All';
  String _statusFilter = 'All'; // All, Graded, Pending, Passed, Failed
  String _sortBy = 'Rank'; // Rank, Name, Roll
  _ResultViewMode _viewMode = _ResultViewMode.cards;

  @override
  void initState() {
    super.initState();
    _selectedShift = (widget.exam.shift.isNotEmpty && widget.exam.shift != 'All') ? widget.exam.shift : 'All';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final rosterQuery = ExamRosterQuery(
      classroom: widget.exam.classroom,
      shift: _selectedShift == 'All' ? null : _selectedShift,
    );
    final rosterAsync = ref.watch(_examRosterProvider(rosterQuery));
    final resultsAsync = ref.watch(examResultsProvider(widget.exam.id));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Advanced Page Header with Quick Export Actions
          ABMPageHeader(
            title: widget.exam.name,
            subtitle: '${widget.exam.classroom} · ${widget.exam.shift.isEmpty ? 'Shift-1' : widget.exam.shift}${widget.exam.assignedTeacher.isNotEmpty ? ' · Teacher: ${widget.exam.assignedTeacher}' : ''}',
            actions: [
              FilledButton.icon(
                onPressed: () {
                  final students = rosterAsync.value ?? const <StudentModel>[];
                  final results = resultsAsync.value ?? const <ExamResult>[];
                  if (students.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No student records to export.')));
                    return;
                  }
                  printClassResultGazette(
                    exam: widget.exam,
                    results: results,
                    students: students,
                  );
                },
                icon: const Icon(LucideIcons.fileSpreadsheet, size: 15),
                label: const Text('Export Gazette PDF', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Gap(6),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Results',
                onPressed: () {
                  ref.invalidate(_examRosterProvider(rosterQuery));
                  ref.invalidate(examResultsProvider(widget.exam.id));
                },
              ),
            ],
          ),

          Expanded(
            child: rosterAsync.when(
              data: (allStudents) {
                if (allStudents.isEmpty) {
                  return AbmEmptyState(
                    icon: LucideIcons.users,
                    title: 'No students found',
                    message: _selectedShift == 'All'
                        ? 'No students enrolled in ${widget.exam.classroom}.'
                        : 'No students in ${widget.exam.classroom} for $_selectedShift.',
                  );
                }

                final results = resultsAsync.value ?? const <ExamResult>[];
                final resultsByStudent = {for (final r in results) r.studentId: r};

                // Analytics & Metrics Calculations
                final gradedResults = results.where((r) => r.maxTotal > 0).toList();
                final gradedCount = gradedResults.length;
                final totalStudents = allStudents.length;
                final evaluationPct = totalStudents > 0 ? (gradedCount / totalStudents) * 100 : 0.0;

                final classAvg = gradedResults.isNotEmpty
                    ? gradedResults.map((r) => r.percentage).reduce((a, b) => a + b) / gradedResults.length
                    : 0.0;

                ExamResult? topperResult;
                StudentModel? topperStudent;
                if (gradedResults.isNotEmpty) {
                  gradedResults.sort((a, b) => b.percentage.compareTo(a.percentage));
                  topperResult = gradedResults.first;
                  topperStudent = allStudents.where((s) => s.id == topperResult?.studentId).firstOrNull;
                }

                final passedCount = gradedResults.where((r) => r.percentage >= 40).length;
                final passRate = gradedResults.isNotEmpty ? (passedCount / gradedResults.length) * 100 : 0.0;

                // Grade Breakdown map
                final gradeCounts = <String, int>{'A+': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
                for (final r in gradedResults) {
                  final g = r.grade.trim();
                  if (gradeCounts.containsKey(g)) {
                    gradeCounts[g] = (gradeCounts[g] ?? 0) + 1;
                  }
                }

                // Filter & Sort students
                var displayStudents = allStudents.where((s) {
                  final r = resultsByStudent[s.id];

                  // Search filter
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    final matchName = s.fullName.toLowerCase().contains(q);
                    final matchId = (s.admissionNumber).toLowerCase().contains(q);
                    if (!matchName && !matchId) return false;
                  }

                  // Status filter
                  if (_statusFilter == 'Graded' && r == null) return false;
                  if (_statusFilter == 'Pending' && r != null) return false;
                  if (_statusFilter == 'Passed' && (r == null || r.percentage < 40)) return false;
                  if (_statusFilter == 'Failed' && (r == null || r.percentage >= 40)) return false;

                  // Grade filter
                  if (_gradeFilter != 'All' && r?.grade != _gradeFilter) return false;

                  return true;
                }).toList();

                // Sort students
                displayStudents.sort((a, b) {
                  final ra = resultsByStudent[a.id];
                  final rb = resultsByStudent[b.id];

                  if (_sortBy == 'Rank') {
                    if (ra != null && rb != null) return rb.percentage.compareTo(ra.percentage);
                    if (ra != null) return -1;
                    if (rb != null) return 1;
                    return a.fullName.compareTo(b.fullName);
                  } else if (_sortBy == 'Name') {
                    return a.fullName.compareTo(b.fullName);
                  } else {
                    return (a.admissionNumber).compareTo(b.admissionNumber);
                  }
                });

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  children: [
                    // Advanced Performance KPI Strip
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        final kpis = [
                          _MetricStatCard(
                            label: 'Class Average',
                            value: '${classAvg.toStringAsFixed(1)}%',
                            subtext: '$gradedCount of $totalStudents graded',
                            icon: LucideIcons.trendingUp,
                            color: const Color(0xFF2563EB),
                          ),
                          _MetricStatCard(
                            label: 'Class Topper',
                            value: topperResult != null ? '${topperResult.percentage}%' : 'N/A',
                            subtext: topperStudent != null ? topperStudent.fullName : 'No records yet',
                            icon: LucideIcons.crown,
                            color: const Color(0xFFD97706),
                          ),
                          _MetricStatCard(
                            label: 'Pass Rate',
                            value: '${passRate.toStringAsFixed(1)}%',
                            subtext: '$passedCount passed evaluation',
                            icon: LucideIcons.checkCircle2,
                            color: const Color(0xFF059669),
                          ),
                          _MetricStatCard(
                            label: 'Evaluation Progress',
                            value: '${evaluationPct.toStringAsFixed(0)}%',
                            subtext: '$gradedCount / $totalStudents students evaluated',
                            icon: LucideIcons.pieChart,
                            color: const Color(0xFF7C3AED),
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            children: [
                              for (int i = 0; i < kpis.length; i++) ...[
                                if (i > 0) const Gap(10),
                                Expanded(child: kpis[i]),
                              ],
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Row(children: [Expanded(child: kpis[0]), const Gap(10), Expanded(child: kpis[1])]),
                            const Gap(10),
                            Row(children: [Expanded(child: kpis[2]), const Gap(10), Expanded(child: kpis[3])]),
                          ],
                        );
                      },
                    ),

                    const Gap(14),

                    // Interactive Grade Distribution Filter Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grade Breakdown & Filter',
                                style: typography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: colors.textSecondary),
                              ),
                              if (_gradeFilter != 'All')
                                TextButton(
                                  onPressed: () => setState(() => _gradeFilter = 'All'),
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: const Text('Clear grade filter', style: TextStyle(fontSize: 11)),
                                ),
                            ],
                          ),
                          const Gap(8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: Text('All (${gradedResults.length})', style: const TextStyle(fontSize: 11)),
                                  selected: _gradeFilter == 'All',
                                  onSelected: (val) {
                                    if (val) setState(() => _gradeFilter = 'All');
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                                for (final entry in gradeCounts.entries) ...[
                                  const Gap(6),
                                  ChoiceChip(
                                    label: Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    selected: _gradeFilter == entry.key,
                                    onSelected: (val) {
                                      setState(() => _gradeFilter = val ? entry.key : 'All');
                                    },
                                    selectedColor: gradeColor(context, entry.key).withValues(alpha: 0.2),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    // Search, Shift, Status & View Mode Controls
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (val) => setState(() => _search = val.trim()),
                                  decoration: InputDecoration(
                                    hintText: 'Search student by name or roll number...',
                                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                                  ),
                                ),
                              ),
                              const Gap(10),
                              // View mode toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.layoutList, size: 16),
                                      tooltip: 'Student Cards',
                                      color: _viewMode == _ResultViewMode.cards ? colors.primary : colors.textSecondary,
                                      onPressed: () => setState(() => _viewMode = _ResultViewMode.cards),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.table, size: 16),
                                      tooltip: 'Marks Matrix Table',
                                      color: _viewMode == _ResultViewMode.matrix ? colors.primary : colors.textSecondary,
                                      onPressed: () => setState(() => _viewMode = _ResultViewMode.matrix),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.barChart2, size: 16),
                                      tooltip: 'Subject Analytics',
                                      color: _viewMode == _ResultViewMode.analytics ? colors.primary : colors.textSecondary,
                                      onPressed: () => setState(() => _viewMode = _ResultViewMode.analytics),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Shift Chip
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: ['All', 'Shift-1', 'Shift-2'].map((s) {
                                  final isSel = _selectedShift == s;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(s == 'All' ? 'All Shifts' : s, style: const TextStyle(fontSize: 11)),
                                      selected: isSel,
                                      onSelected: (val) {
                                        if (val) setState(() => _selectedShift = s);
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const Gap(8),
                              // Status Chip
                              DropdownButton<String>(
                                value: _statusFilter,
                                underline: const SizedBox.shrink(),
                                style: TextStyle(fontSize: 12, color: colors.textPrimary, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                                  DropdownMenuItem(value: 'Graded', child: Text('Graded Only')),
                                  DropdownMenuItem(value: 'Pending', child: Text('Pending Only')),
                                  DropdownMenuItem(value: 'Passed', child: Text('Passed Only')),
                                  DropdownMenuItem(value: 'Failed', child: Text('Failed Only')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _statusFilter = v);
                                },
                              ),
                              const Gap(8),
                              // Sort by
                              DropdownButton<String>(
                                value: _sortBy,
                                underline: const SizedBox.shrink(),
                                style: TextStyle(fontSize: 12, color: colors.textPrimary, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'Rank', child: Text('Sort: Highest Score')),
                                  DropdownMenuItem(value: 'Name', child: Text('Sort: Name (A-Z)')),
                                  DropdownMenuItem(value: 'Roll', child: Text('Sort: Admission / Roll')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _sortBy = v);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(14),

                    // Results content depending on View Mode
                    if (displayStudents.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text('No students match the selected filters.', style: typography.bodyMediumSemiBold),
                      )
                    else if (_viewMode == _ResultViewMode.cards)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayStudents.length,
                        separatorBuilder: (_, _) => const Gap(10),
                        itemBuilder: (context, i) {
                          final student = displayStudents[i];
                          final result = resultsByStudent[student.id];
                          final rankIndex = i + 1;

                          return _StudentResultDetailedCard(
                            student: student,
                            result: result,
                            exam: widget.exam,
                            rank: _sortBy == 'Rank' ? rankIndex : null,
                            onEditMarks: () async {
                              final saved = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: colors.cardBackground,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (_) => _MarksSheet(
                                  exam: widget.exam,
                                  student: student,
                                  existing: result,
                                  studentsList: displayStudents,
                                  currentIndex: i,
                                ),
                              );
                              if (saved == true) {
                                ref.invalidate(examResultsProvider(widget.exam.id));
                              }
                            },
                            onDownloadReport: result == null
                                ? null
                                : () => printReportCard(
                                      exam: widget.exam,
                                      result: result,
                                      studentName: student.fullName,
                                      admissionNumber: student.admissionNumber,
                                    ),
                          );
                        },
                      )
                    else if (_viewMode == _ResultViewMode.matrix)
                      _ExamMarksMatrixTable(
                        exam: widget.exam,
                        students: displayStudents,
                        resultsByStudent: resultsByStudent,
                        onEditMarks: (student, res) async {
                          final saved = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: colors.cardBackground,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (_) => _MarksSheet(
                              exam: widget.exam,
                              student: student,
                              existing: res,
                            ),
                          );
                          if (saved == true) {
                            ref.invalidate(examResultsProvider(widget.exam.id));
                          }
                        },
                      )
                    else
                      _ExamSubjectAnalyticsView(
                        exam: widget.exam,
                        results: results,
                        students: allStudents,
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(_examRosterProvider(rosterQuery)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metric Stat Card Widget ─────────────────────────────────────────────────

class _MetricStatCard extends StatelessWidget {
  const _MetricStatCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const Gap(4),
          Text(value, style: t.h3.copyWith(fontWeight: FontWeight.bold)),
          Text(subtext, style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Detailed Student Result Card ────────────────────────────────────────────

class _StudentResultDetailedCard extends StatelessWidget {
  const _StudentResultDetailedCard({
    required this.student,
    required this.result,
    required this.exam,
    this.rank,
    required this.onEditMarks,
    this.onDownloadReport,
  });

  final StudentModel student;
  final ExamResult? result;
  final Exam exam;
  final int? rank;
  final VoidCallback onEditMarks;
  final VoidCallback? onDownloadReport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final maxBySubject = {for (final s in exam.subjects) s.name: s.maxMarks};

    Color rankBadgeColor = colors.primary;
    if (rank == 1) rankBadgeColor = const Color(0xFFD97706); // Gold
    if (rank == 2) rankBadgeColor = const Color(0xFF64748B); // Silver
    if (rank == 3) rankBadgeColor = const Color(0xFFB45309); // Bronze

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank Badge if applicable
              if (rank != null && result != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rankBadgeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rankBadgeColor,
                    ),
                  ),
                ),
                const Gap(10),
              ] else ...[
                abmInitialsAvatar(context, student.fullName),
                const Gap(10),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName, style: typography.bodyMediumSemiBold),
                    const Gap(2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (student.admissionNumber.isNotEmpty)
                          Text('ID: ${student.admissionNumber}', style: typography.bodySmall.copyWith(fontSize: 11, color: colors.textSecondary)),
                        if (student.shift != null && student.shift!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(student.shift!, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Grade badge or Pending pill
              if (result != null)
                AbmStatusPill(label: result!.grade, color: gradeColor(context, result!.grade))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text('Pending Marks', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                ),
            ],
          ),

          const Gap(12),

          // Total and Percentage
          if (result != null) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: result!.percentage / 100,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(gradeColor(context, result!.grade)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  '${result!.total} / ${result!.maxTotal} (${result!.percentage}%)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(10),

            // Subject marks chips
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: result!.marks.map((m) {
                final max = maxBySubject[m.subject] ?? 100;
                final isPassing = max > 0 ? (m.score / max) >= 0.4 : true;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPassing ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isPassing ? colors.border : const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.subject, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      const Gap(4),
                      Text(
                        '${m.score}/$max',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPassing ? colors.primary : colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            if (result!.remarks.isNotEmpty) ...[
              const Gap(8),
              Text(
                'Remark: ${result!.remarks}',
                style: typography.bodySmall.copyWith(fontSize: 11, fontStyle: FontStyle.italic, color: colors.textSecondary),
              ),
            ],
          ],

          const Gap(12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onEditMarks,
                  icon: const Icon(LucideIcons.pencil, size: 14),
                  label: Text(result == null ? 'Enter Marks' : 'Edit Marks', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (onDownloadReport != null) ...[
                const Gap(8),
                IconButton.outlined(
                  onPressed: onDownloadReport,
                  icon: const Icon(LucideIcons.printer, size: 16),
                  tooltip: 'Print Report Card',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Marks Matrix Table View (Spreadsheet Style) ─────────────────────────────

class _ExamMarksMatrixTable extends StatelessWidget {
  const _ExamMarksMatrixTable({
    required this.exam,
    required this.students,
    required this.resultsByStudent,
    required this.onEditMarks,
  });

  final Exam exam;
  final List<StudentModel> students;
  final Map<String, ExamResult> resultsByStudent;
  final void Function(StudentModel student, ExamResult? existing) onEditMarks;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(colors.primary.withValues(alpha: 0.05)),
          columnSpacing: 18,
          columns: [
            const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Shift', style: TextStyle(fontWeight: FontWeight.bold))),
            ...exam.subjects.map(
              (s) => DataColumn(
                label: Text('${s.name}\n(${s.maxMarks})', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
            const DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('%', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            for (int i = 0; i < students.length; i++) ...[
              _buildRow(context, i + 1, students[i], resultsByStudent[students[i].id]),
            ],
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, int index, StudentModel student, ExamResult? result) {
    final colors = context.colors;
    final marksMap = {for (final m in (result?.marks ?? const <ExamMark>[])) m.subject: m.score};

    return DataRow(
      cells: [
        DataCell(Text('$index', style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(Text(student.shift ?? exam.shift, style: const TextStyle(fontSize: 11))),
        ...exam.subjects.map((subj) {
          final score = marksMap[subj.name];
          return DataCell(
            Center(
              child: Text(
                score != null ? score.toString() : '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: score != null && score < (subj.maxMarks * 0.4) ? colors.red : colors.textPrimary,
                ),
              ),
            ),
          );
        }),
        DataCell(Text(result != null ? '${result.total}/${result.maxTotal}' : '-', style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(result != null ? '${result.percentage}%' : '-', style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          result != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gradeColor(context, result.grade).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(result.grade, style: TextStyle(fontWeight: FontWeight.bold, color: gradeColor(context, result.grade))),
                )
              : const Text('-'),
        ),
        DataCell(
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 14),
            tooltip: 'Enter Marks',
            onPressed: () => onEditMarks(student, result),
          ),
        ),
      ],
    );
  }
}

// ─── Subject Analytics View ──────────────────────────────────────────────────

class _ExamSubjectAnalyticsView extends StatelessWidget {
  const _ExamSubjectAnalyticsView({
    required this.exam,
    required this.results,
    required this.students,
  });

  final Exam exam;
  final List<ExamResult> results;
  final List<StudentModel> students;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exam.subjects.length,
      separatorBuilder: (_, _) => const Gap(12),
      itemBuilder: (_, i) {
        final subj = exam.subjects[i];

        // Gather scores for this subject
        final scores = <num>[];
        for (final r in results) {
          final m = r.marks.where((mk) => mk.subject == subj.name).firstOrNull;
          if (m != null) scores.add(m.score);
        }

        final count = scores.length;
        final avg = count > 0 ? scores.reduce((a, b) => a + b) / count : 0.0;
        final highest = count > 0 ? scores.reduce((a, b) => a > b ? a : b) : 0;
        final lowest = count > 0 ? scores.reduce((a, b) => a < b ? a : b) : 0;
        final passingCount = count > 0 ? scores.where((s) => s >= (subj.maxMarks * 0.4)).length : 0;
        final passPct = count > 0 ? (passingCount / count) * 100 : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.bookOpen, size: 18, color: colors.primary),
                      ),
                      const Gap(10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subj.name, style: typography.bodyLargeSemiBold),
                          Text(
                            subj.teacher.isNotEmpty ? 'Teacher: ${subj.teacher}' : 'Max Marks: ${subj.maxMarks}',
                            style: typography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Max: ${subj.maxMarks}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                    ),
                  ),
                ],
              ),
              const Gap(14),
              Row(
                children: [
                  Expanded(
                    child: _analyticBox(context, 'Average', '${avg.toStringAsFixed(1)} / ${subj.maxMarks}', colors.primary),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _analyticBox(context, 'Highest', '$highest / ${subj.maxMarks}', colors.green),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _analyticBox(context, 'Lowest', '$lowest / ${subj.maxMarks}', colors.red),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _analyticBox(context, 'Pass Rate', '${passPct.toStringAsFixed(0)}%', colors.warning),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticBox(BuildContext context, String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const Gap(2),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ─── Real-Time Interactive Marks Sheet Modal ─────────────────────────────────

class _MarksSheet extends ConsumerStatefulWidget {
  const _MarksSheet({
    required this.exam,
    required this.student,
    this.existing,
    this.studentsList,
    this.currentIndex,
  });

  final Exam exam;
  final StudentModel student;
  final ExamResult? existing;
  final List<StudentModel>? studentsList;
  final int? currentIndex;

  @override
  ConsumerState<_MarksSheet> createState() => _MarksSheetState();
}

class _MarksSheetState extends ConsumerState<_MarksSheet> {
  late final Map<String, TextEditingController> _ctrls;
  late final TextEditingController _remarks;
  bool _saving = false;

  num _computedTotal = 0;
  num _computedMaxTotal = 0;
  num _computedPercentage = 0;
  String _computedGrade = 'F';

  @override
  void initState() {
    super.initState();
    final existingScores = {for (final m in widget.existing?.marks ?? const []) m.subject: m.score};
    _ctrls = {
      for (final s in widget.exam.subjects)
        s.name: TextEditingController(
          text: existingScores[s.name] != null
              ? (existingScores[s.name]! % 1 == 0
                  ? existingScores[s.name]!.toInt().toString()
                  : existingScores[s.name]!.toString())
              : '',
        ),
    };
    _remarks = TextEditingController(text: widget.existing?.remarks ?? '');

    for (final c in _ctrls.values) {
      c.addListener(_recomputeTotals);
    }
    _recomputeTotals();
  }

  void _recomputeTotals() {
    num total = 0;
    num maxTotal = 0;
    for (final s in widget.exam.subjects) {
      maxTotal += s.maxMarks;
      final text = _ctrls[s.name]?.text.trim().replaceAll(',', '.') ?? '';
      final val = num.tryParse(text) ?? 0;
      total += (val < 0) ? 0 : (val > s.maxMarks ? s.maxMarks : val);
    }
    final pct = maxTotal > 0 ? (total / maxTotal) * 100 : 0.0;
    String g = 'F';
    if (pct >= 90) {
      g = 'A+';
    } else if (pct >= 80) {
      g = 'A';
    } else if (pct >= 70) {
      g = 'B';
    } else if (pct >= 60) {
      g = 'C';
    } else if (pct >= 50) {
      g = 'D';
    }

    setState(() {
      _computedTotal = (total * 10).round() / 10;
      _computedMaxTotal = maxTotal;
      _computedPercentage = (pct * 10).round() / 10;
      _computedGrade = g;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save({bool proceedNext = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final marks = <String, num>{};
      for (final s in widget.exam.subjects) {
        final text = _ctrls[s.name]!.text.trim().replaceAll(',', '.');
        final val = num.tryParse(text) ?? 0;
        marks[s.name] = (val < 0) ? 0 : (val > s.maxMarks ? s.maxMarks : val);
      }
      await ref.read(examRepositoryProvider).upsertResult(
            widget.exam.id,
            studentId: widget.student.id,
            marks: marks,
            remarks: _remarks.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        if (proceedNext && widget.studentsList != null && widget.currentIndex != null) {
          final nextIdx = widget.currentIndex! + 1;
          if (nextIdx < widget.studentsList!.length) {
            final nextStudent = widget.studentsList![nextIdx];
            showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              backgroundColor: context.colors.cardBackground,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _MarksSheet(
                exam: widget.exam,
                student: nextStudent,
                studentsList: widget.studentsList,
                currentIndex: nextIdx,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final studentShift = widget.student.shift;
    final shiftTag = (studentShift != null && studentShift.isNotEmpty) ? studentShift : widget.exam.shift;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)))),
            const Gap(14),

            // Header with Student Name & Live Grade Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.student.fullName, style: typography.h4),
                      Text(
                        '${widget.exam.name} · ${widget.exam.classroom}${shiftTag.isNotEmpty ? ' · $shiftTag' : ''}',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gradeColor(context, _computedGrade).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gradeColor(context, _computedGrade).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _computedGrade,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: gradeColor(context, _computedGrade)),
                      ),
                      Text(
                        '$_computedPercentage%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: gradeColor(context, _computedGrade)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(14),

            // Real-Time Calculation Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calculated Total:', style: typography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '$_computedTotal / $_computedMaxTotal',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                ],
              ),
            ),

            const Gap(16),

            // Subject Marks Inputs
            for (final s in widget.exam.subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: typography.bodyMediumSemiBold),
                          if (s.teacher.isNotEmpty)
                            Text('Teacher: ${s.teacher}', style: typography.bodySmall.copyWith(fontSize: 10, color: colors.textSecondary)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _ctrls[s.name],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: const OutlineInputBorder(),
                          suffixText: '/ ${s.maxMarks}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Gap(6),
            ABMTextField(label: 'Teacher Remarks (optional)', hint: 'Any behavioral or performance note...', controller: _remarks, maxLines: 2),

            const Gap(18),

            Row(
              children: [
                Expanded(
                  child: ABMButton(
                    text: 'Save Marks',
                    isLoading: _saving,
                    onPressed: () => _save(proceedNext: false),
                  ),
                ),
                if (widget.studentsList != null && widget.currentIndex != null && widget.currentIndex! + 1 < widget.studentsList!.length) ...[
                  const Gap(10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _save(proceedNext: true),
                      icon: const Icon(LucideIcons.arrowRight, size: 14),
                      label: const Text('Save & Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
