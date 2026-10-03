import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/exams/data/exam_repository.dart';
import 'package:abm_madrasa/features/exams/presentation/report_card_pdf.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

Color gradeColor(BuildContext context, String g) {
  final c = context.colors;
  if (g == 'A+' || g == 'A') return c.green;
  if (g == 'B' || g == 'C') return c.primary;
  if (g == 'D') return c.warning;
  return c.red;
}

final _examRosterProvider = FutureProvider.autoDispose.family<List<StudentModel>, String>((ref, classroom) {
  final inst = ref.watch(selectedInstituteProvider).id;
  return ref.read(studentRepositoryProvider).getStudents(instituteId: inst, classroom: classroom);
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

// ─── Student results ─────────────────────────────────────────────────────────

class _StudentResultsView extends ConsumerWidget {
  const _StudentResultsView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(myResultsProvider);
    final name = ref.watch(authControllerProvider).value?.username ?? 'Student';
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(title: 'My Results', subtitle: 'Exam results and report cards', height: context.isMobile ? 160 : 180),
          Expanded(
            child: async.when(
              data: (results) {
                if (results.isEmpty) {
                  return const AbmEmptyState(
                    icon: LucideIcons.award,
                    title: 'No results yet',
                    message: 'Your exam results will appear here once published.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Gap(12),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    return _ResultCard(
                      result: r,
                      onDownload: r.exam == null
                          ? null
                          : () => printReportCard(exam: r.exam!, result: r, studentName: name),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(message: friendlyErrorMessage(e), onRetry: () => ref.invalidate(myResultsProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, this.onDownload});
  final ExamResult result;
  final VoidCallback? onDownload;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final exam = result.exam;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(exam?.name ?? 'Exam', style: t.bodyLargeSemiBold)),
              AbmStatusPill(label: result.grade, color: gradeColor(context, result.grade)),
            ],
          ),
          if (exam?.term.isNotEmpty == true) ...[
            const Gap(2),
            Text(exam!.term, style: t.bodySmall.copyWith(color: colors.textSecondary)),
          ],
          const Gap(12),
          Row(children: [
            Expanded(child: _metric(context, '${result.total}/${result.maxTotal}', 'Total')),
            Expanded(child: _metric(context, '${result.percentage}%', 'Percentage')),
          ]),
          if (result.remarks.isNotEmpty) ...[
            const Gap(8),
            Text(result.remarks, style: t.bodySmall.copyWith(color: colors.textSecondary)),
          ],
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Download report card'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext c, String v, String l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: c.typography.h4.copyWith(color: c.colors.textPrimary)),
        Text(l, style: c.typography.bodySmall.copyWith(color: c.colors.textSecondary)),
      ]);
}

// ─── Staff exams ─────────────────────────────────────────────────────────────

class _StaffExamsView extends ConsumerStatefulWidget {
  const _StaffExamsView();
  @override
  ConsumerState<_StaffExamsView> createState() => _StaffExamsViewState();
}

class _StaffExamsViewState extends ConsumerState<_StaffExamsView> {
  final ScrollController _scrollController = ScrollController();
  String _class = 'All';
  String _searchQuery = '';
  int _page = 1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final classesAsync = ref.watch(classroomControllerProvider);
    final options = classesAsync.maybeWhen(data: (c) => ['All', ...c.map((e) => e.name)], orElse: () => <String>['All']);
    final examQuery = ExamQuery(classroom: _class, page: _page);
    final examsAsync = ref.watch(examsPageProvider(examQuery));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Exams & Results',
            subtitle: 'Create exams and enter marks',
            showBackButton: false,
            compact: true,
            actions: [
              FilledButton.icon(
                onPressed: _createExam,
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
                  ref.invalidate(examsPageProvider);
                  ref.invalidate(examsListProvider);
                },
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Exams',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Expanded(
            child: examsAsync.when(
              data: (pagedResult) {
                final allExams = pagedResult.items;

                // KPI Calculations
                final classesSet = <String>{};
                int totalSubjects = 0;
                for (final e in allExams) {
                  if (e.classroom.isNotEmpty) classesSet.add(e.classroom);
                  totalSubjects += e.subjects.length;
                }

                // Filter by search query
                final filtered = allExams.where((exam) {
                  final subjectsStr = exam.subjects.map((s) => s.name).join(' ');
                  return _searchQuery.isEmpty ||
                      exam.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      exam.classroom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      exam.term.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      subjectsStr.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                    children: [
                      // Top KPI Stat Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          final kpis = [
                            _ExamKpiCard(
                              title: 'Total Exams',
                              value: '${pagedResult.total}',
                              subtext: '${classesSet.length} classes scheduled',
                              icon: LucideIcons.award,
                              color: const Color(0xFF2563EB),
                              badge: 'Evaluations',
                            ),
                            _ExamKpiCard(
                              title: 'Classes Covered',
                              value: '${classesSet.length}',
                              subtext: _class == 'All' ? 'Across all classes' : 'Filtered: $_class',
                              icon: LucideIcons.graduationCap,
                              color: const Color(0xFF059669),
                              badge: 'Active Sections',
                            ),
                            _ExamKpiCard(
                              title: 'Subjects Tested',
                              value: '$totalSubjects',
                              subtext: 'Curriculum evaluations',
                              icon: LucideIcons.bookOpen,
                              color: const Color(0xFFD97706),
                              badge: '$totalSubjects Papers',
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

                      // Search and Filter Toolbar
                      Container(
                        padding: const EdgeInsets.all(12),
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
                                  child: TextField(
                                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                    decoration: InputDecoration(
                                      hintText: 'Search by exam name, class, term, or subject...',
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
                                if (_searchQuery.isNotEmpty || _class != 'All') ...[
                                  const Gap(8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _class = 'All';
                                        _page = 1;
                                      });
                                    },
                                    icon: const Icon(LucideIcons.rotateCcw, size: 14),
                                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),
                            const Gap(10),
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
                                    items: options
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _class = val;
                                          _page = 1;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Gap(16),

                      // Results header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            filtered.isEmpty
                                ? 'No exams found'
                                : 'Exams & Evaluations (${filtered.length})',
                            style: typography.bodyMediumSemiBold,
                          ),
                          if (_class != 'All')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Class: $_class',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                              ),
                            ),
                        ],
                      ),

                      const Gap(10),

                      if (filtered.isEmpty)
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
                                'Tap "New Exam" to create an exam for your classroom.',
                                style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const Gap(16),
                              FilledButton.icon(
                                onPressed: _createExam,
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Create Exam'),
                                style: FilledButton.styleFrom(backgroundColor: colors.primary),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        for (final exam in filtered) ...[
                          _ExamCard(
                            exam: exam,
                            onOpen: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ExamMarksScreen(exam: exam))),
                            onDelete: () => _deleteExam(exam),
                          ),
                          const Gap(12),
                        ],
                        if (pagedResult.totalPages > 1) ...[
                          const Gap(8),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: AbmPaginationBar(
                                page: pagedResult.page,
                                totalPages: pagedResult.totalPages,
                                total: pagedResult.total,
                                onPage: (p) {
                                  setState(() => _page = p);
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            ),
                          ),
                          const Gap(6),
                          Center(
                            child: Text(
                              'Page ${pagedResult.page} of ${pagedResult.totalPages} · ${pagedResult.total} total exams',
                              style: typography.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(message: friendlyErrorMessage(e), onRetry: () {
                ref.invalidate(examsPageProvider);
                ref.invalidate(examsListProvider);
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createExam,
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Create exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _deleteExam(Exam exam) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmActionDialog(context, title: 'Delete exam', message: 'Delete "${exam.name}" and all its results?', icon: LucideIcons.trash2);
    if (!ok) return;
    try {
      await ref.read(examRepositoryProvider).deleteExam(exam.id);
      ref.invalidate(examsPageProvider);
      ref.invalidate(examsListProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Exam deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _createExam() async {
    final classes = ref.read(classroomControllerProvider).maybeWhen(data: (c) => c.map((e) => e.name).toList(), orElse: () => <String>[]);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateExamSheet(classes: classes),
    );
    if (ok == true) {
      ref.invalidate(examsPageProvider);
      ref.invalidate(examsListProvider);
    }
  }
}

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onOpen, required this.onDelete});
  final Exam exam;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.award, color: colors.primary, size: 22),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exam.name, style: typography.bodyLargeSemiBold),
                          const Gap(4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  exam.classroom.isEmpty ? 'All Classes' : exam.classroom,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ),
                              if (exam.term.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    exam.term,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    FilledButton.tonalIcon(
                      onPressed: onOpen,
                      icon: const Icon(LucideIcons.pencil, size: 14),
                      label: const Text('Enter Marks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const Gap(4),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, size: 18, color: colors.red),
                      tooltip: 'Delete Exam',
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (exam.subjects.isNotEmpty) ...[
                  const Gap(12),
                  const Divider(height: 1),
                  const Gap(10),
                  Row(
                    children: [
                      Icon(LucideIcons.bookOpen, size: 13, color: colors.textSecondary),
                      const Gap(6),
                      Text(
                        '${exam.subjects.length} Subjects: ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          exam.subjects.map((s) => s.name).join(' · '),
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

// ─── Create exam sheet ───────────────────────────────────────────────────────

class _CreateExamSheet extends ConsumerStatefulWidget {
  const _CreateExamSheet({required this.classes});
  final List<String> classes;
  @override
  ConsumerState<_CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends ConsumerState<_CreateExamSheet> {
  final _name = TextEditingController();
  final _term = TextEditingController();
  String? _class;
  DateTime? _date;
  final List<({TextEditingController name, TextEditingController max})> _subjects = [
    (name: TextEditingController(), max: TextEditingController(text: '100')),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _term.dispose();
    for (final s in _subjects) { s.name.dispose(); s.max.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) { messenger.showSnackBar(const SnackBar(content: Text('Enter an exam name.'))); return; }
    if (_class == null) { messenger.showSnackBar(const SnackBar(content: Text('Choose a class.'))); return; }
    final subjects = _subjects
        .where((s) => s.name.text.trim().isNotEmpty)
        .map((s) => ExamSubject(name: s.name.text.trim(), maxMarks: int.tryParse(s.max.text.trim()) ?? 100))
        .toList();
    if (subjects.isEmpty) { messenger.showSnackBar(const SnackBar(content: Text('Add at least one subject.'))); return; }
    setState(() => _saving = true);
    try {
      await ref.read(examRepositoryProvider).createExam(
            name: _name.text.trim(), classroom: _class!, term: _term.text.trim(), date: _date, subjects: subjects);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) { setState(() => _saving = false); messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e)))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)))),
            const Gap(14),
            Text('Create exam', style: context.typography.h4),
            const Gap(16),
            ABMTextField(label: 'Exam name', hint: 'e.g. Term 1 Exam', controller: _name),
            const Gap(12),
            DropdownButtonFormField<String>(
              initialValue: _class,
              decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
              items: widget.classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _class = v),
            ),
            const Gap(12),
            ABMTextField(label: 'Term (optional)', hint: 'e.g. 2026', controller: _term),
            const Gap(16),
            Row(children: [
              Text('Subjects', style: context.typography.bodyMediumSemiBold),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _subjects.add((name: TextEditingController(), max: TextEditingController(text: '100')))),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add subject'),
              ),
            ]),
            const Gap(4),
            for (var i = 0; i < _subjects.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(flex: 3, child: ABMTextField(label: 'Subject', hint: 'e.g. Quran', controller: _subjects[i].name)),
                  const Gap(8),
                  Expanded(flex: 1, child: ABMTextField(label: 'Max', hint: '100', controller: _subjects[i].max, keyboardType: TextInputType.number)),
                  if (_subjects.length > 1)
                    IconButton(icon: Icon(LucideIcons.x, size: 18, color: colors.red), onPressed: () => setState(() {
                      _subjects[i].name.dispose(); _subjects[i].max.dispose(); _subjects.removeAt(i);
                    })),
                ]),
              ),
            const Gap(16),
            ABMButton(text: 'Create exam', isLoading: _saving, onPressed: _save),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}

// ─── Marks entry ─────────────────────────────────────────────────────────────

class _ExamMarksScreen extends ConsumerWidget {
  const _ExamMarksScreen({required this.exam});
  final Exam exam;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final rosterAsync = ref.watch(_examRosterProvider(exam.classroom));
    final resultsAsync = ref.watch(examResultsProvider(exam.id));
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(title: exam.name, subtitle: '${exam.classroom} · enter marks'),
          Expanded(
            child: rosterAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return const AbmEmptyState(icon: LucideIcons.users, title: 'No students in this class');
                }
                final byStudent = {for (final r in (resultsAsync.value ?? const <ExamResult>[])) r.studentId: r};
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (_, i) {
                    final s = students[i];
                    final r = byStudent[s.id];
                    return AbmListRow(
                      leading: abmInitialsAvatar(context, s.fullName),
                      title: s.fullName,
                      subtitle: r == null ? 'Not entered' : '${r.total}/${r.maxTotal} · ${r.percentage}%',
                      trailing: r == null
                          ? Icon(LucideIcons.plusCircle, color: colors.primary, size: 20)
                          : AbmStatusPill(label: r.grade, color: gradeColor(context, r.grade)),
                      onTap: () async {
                        final saved = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: colors.cardBackground,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => _MarksSheet(exam: exam, student: s, existing: r),
                        );
                        if (saved == true) ref.invalidate(examResultsProvider(exam.id));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(message: friendlyErrorMessage(e), onRetry: () => ref.invalidate(_examRosterProvider(exam.classroom))),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarksSheet extends ConsumerStatefulWidget {
  const _MarksSheet({required this.exam, required this.student, this.existing});
  final Exam exam;
  final StudentModel student;
  final ExamResult? existing;
  @override
  ConsumerState<_MarksSheet> createState() => _MarksSheetState();
}

class _MarksSheetState extends ConsumerState<_MarksSheet> {
  late final Map<String, TextEditingController> _ctrls;
  late final TextEditingController _remarks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existingScores = {for (final m in widget.existing?.marks ?? const []) m.subject: m.score};
    _ctrls = {
      for (final s in widget.exam.subjects)
        s.name: TextEditingController(text: existingScores[s.name]?.toString() ?? ''),
    };
    _remarks = TextEditingController(text: widget.existing?.remarks ?? '');
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) { c.dispose(); }
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final marks = <String, num>{};
      for (final s in widget.exam.subjects) {
        marks[s.name] = num.tryParse(_ctrls[s.name]!.text.trim()) ?? 0;
      }
      await ref.read(examRepositoryProvider).upsertResult(widget.exam.id, studentId: widget.student.id, marks: marks, remarks: _remarks.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) { setState(() => _saving = false); messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e)))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)))),
            const Gap(14),
            Text('Marks — ${widget.student.fullName}', style: context.typography.h4),
            const Gap(16),
            for (final s in widget.exam.subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: Text(s.name, style: context.typography.bodyMedium)),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _ctrls[s.name],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(isDense: true, border: const OutlineInputBorder(), suffixText: '/ ${s.maxMarks}'),
                    ),
                  ),
                ]),
              ),
            const Gap(6),
            ABMTextField(label: 'Remarks (optional)', hint: 'Any comments…', controller: _remarks, maxLines: 2),
            const Gap(18),
            ABMButton(text: 'Save marks', isLoading: _saving, onPressed: _save),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
