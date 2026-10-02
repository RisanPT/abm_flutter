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
  String _class = 'All';
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final classesAsync = ref.watch(classroomControllerProvider);
    final options = classesAsync.maybeWhen(data: (c) => ['All', ...c.map((e) => e.name)], orElse: () => <String>['All']);
    final examQuery = ExamQuery(classroom: _class, page: _page);
    final examsAsync = ref.watch(examsPageProvider(examQuery));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(title: 'Exams & Results', subtitle: 'Create exams and enter marks', height: context.isMobile ? 160 : 180),
          Container(
            color: colors.background,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: options.map((c) {
                final sel = c == _class;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _class = c;
                      _page = 1;
                    }),
                    selectedColor: colors.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: sel ? colors.primary : colors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
                  ),
                );
              }).toList()),
            ),
          ),
          Expanded(
            child: examsAsync.when(
              data: (pagedResult) {
                final exams = pagedResult.items;
                if (exams.isEmpty) {
                  return const AbmEmptyState(icon: LucideIcons.award, title: 'No exams yet', message: 'Tap "Create exam" to add one.');
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: exams.length,
                        separatorBuilder: (_, _) => const Gap(10),
                        itemBuilder: (_, i) => _ExamCard(
                          exam: exams[i],
                          onOpen: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ExamMarksScreen(exam: exams[i]))),
                          onDelete: () => _deleteExam(exams[i]),
                        ),
                      ),
                    ),
                    if (pagedResult.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: AbmPaginationBar(
                          page: pagedResult.page,
                          totalPages: pagedResult.totalPages,
                          total: pagedResult.total,
                          onPage: (p) => setState(() => _page = p),
                        ),
                      ),
                  ],
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

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onOpen, required this.onDelete});
  final Exam exam;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AbmListRow(
      onTap: onOpen,
      leading: CircleAvatar(radius: 20, backgroundColor: colors.primary.withValues(alpha: 0.12), child: Icon(LucideIcons.award, color: colors.primary, size: 18)),
      title: exam.name,
      subtitle: '${exam.classroom} · ${exam.subjects.length} subjects${exam.term.isNotEmpty ? ' · ${exam.term}' : ''}',
      trailing: IconButton(icon: Icon(LucideIcons.trash2, size: 18, color: colors.red), tooltip: 'Delete', onPressed: onDelete),
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
