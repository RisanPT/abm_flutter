import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/hifz/data/hifz_repository.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _qualityOptions = ['Excellent', 'Good', 'Average', 'Needs work'];

Color qualityColor(BuildContext context, String q) {
  final colors = context.colors;
  switch (q) {
    case 'Excellent':
      return colors.green;
    case 'Good':
      return colors.primary;
    case 'Average':
      return colors.warning;
    case 'Needs work':
      return colors.red;
    default:
      return colors.textSecondary;
  }
}

// Roster for a class (for the teacher logging view).
final _hifzRosterProvider =
    FutureProvider.autoDispose.family<List<StudentModel>, String>((ref, classroom) {
  final inst = ref.watch(selectedInstituteProvider).id;
  return ref.read(studentRepositoryProvider).getStudents(
        instituteId: inst,
        classroom: classroom == 'All' ? null : classroom,
      );
});

class HifzScreen extends ConsumerWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user?.role == AppRoles.student) return const _StudentHifzView();
    return const _TeacherHifzView();
  }
}

// ─── Student / parent view ───────────────────────────────────────────────────

class _StudentHifzView extends ConsumerWidget {
  const _StudentHifzView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(myHifzProvider);
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'My Hifz',
            subtitle: 'Quran memorization progress',
            height: context.isMobile ? 160 : 180,
          ),
          Expanded(
            child: async.when(
              data: (h) => _historyList(context, h, ownerLabel: 'You'),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(myHifzProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _historyList(BuildContext context, HifzHistory h, {required String ownerLabel}) {
  if (h.records.isEmpty) {
    return const AbmEmptyState(
      icon: LucideIcons.bookOpen,
      title: 'No Hifz entries yet',
      message: 'Daily memorization progress will appear here once the teacher logs it.',
    );
  }
  return ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
    children: [
      _ProgressCard(history: h),
      const Gap(16),
      Text('History', style: context.typography.h4),
      const Gap(10),
      for (final r in h.records) ...[
        _HifzEntryCard(record: r),
        const Gap(10),
      ],
    ],
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.history});
  final HifzHistory history;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final last = history.lastEntry;
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(LucideIcons.bookOpen, color: colors.primary, size: 22),
              const Gap(10),
              Text('Memorization progress', style: t.bodyLargeSemiBold),
            ],
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(child: _stat(context, '${history.daysLogged}', 'Days logged')),
              Expanded(child: _stat(context, last?.sabaqLabel ?? '—', 'Latest Sabaq')),
            ],
          ),
          if (last?.quality.isNotEmpty == true) ...[
            const Gap(12),
            Row(children: [
              Text('Last rating: ', style: t.bodySmall.copyWith(color: colors.textSecondary)),
              AbmStatusPill(label: last!.quality, color: qualityColor(context, last.quality)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: context.typography.h4.copyWith(color: context.colors.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
        ],
      );
}

class _HifzEntryCard extends StatelessWidget {
  const _HifzEntryCard({required this.record});
  final HifzRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    Widget line(String label, String value) => value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 62, child: Text(label, style: t.bodySmall.copyWith(color: colors.textSecondary))),
                Expanded(child: Text(value, style: t.bodyMedium.copyWith(color: colors.textPrimary))),
              ],
            ),
          );

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
            children: [
              Icon(LucideIcons.calendar, size: 15, color: colors.textSecondary),
              const Gap(6),
              Text(record.date != null ? DateFormat('EEE, dd MMM yyyy').format(record.date!.toLocal()) : '',
                  style: t.bodyMediumSemiBold),
              const Spacer(),
              if (record.quality.isNotEmpty)
                AbmStatusPill(label: record.quality, color: qualityColor(context, record.quality)),
            ],
          ),
          line('Sabaq', record.sabaqLabel == '—' ? '' : record.sabaqLabel),
          line('Sabqi', record.sabqi),
          line('Manzil', record.manzil),
          line('Notes', record.notes),
        ],
      ),
    );
  }
}

// ─── Teacher / admin view ────────────────────────────────────────────────────

class _TeacherHifzView extends ConsumerStatefulWidget {
  const _TeacherHifzView();
  @override
  ConsumerState<_TeacherHifzView> createState() => _TeacherHifzViewState();
}

class _TeacherHifzViewState extends ConsumerState<_TeacherHifzView> {
  String _class = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final classesAsync = ref.watch(classroomControllerProvider);
    final options = classesAsync.maybeWhen(
      data: (c) => ['All', ...c.map((e) => e.name)],
      orElse: () => <String>['All'],
    );
    final rosterAsync = ref.watch(_hifzRosterProvider(_class));
    final todayAsync = ref.watch(classHifzTodayProvider(_class));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Hifz Tracker',
            subtitle: 'Log daily Sabaq · Sabqi · Manzil',
            height: context.isMobile ? 160 : 180,
          ),
          Container(
            color: colors.background,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((c) {
                  final sel = c == _class;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: sel,
                      onSelected: (_) => setState(() => _class = c),
                      selectedColor: colors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: sel ? colors.primary : colors.textSecondary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: rosterAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return const AbmEmptyState(
                    icon: LucideIcons.users,
                    title: 'No students',
                    message: 'Pick a class to log Hifz for its students.',
                  );
                }
                final today = todayAsync.value ?? const <HifzRecord>[];
                final byStudent = {for (final r in today) r.studentId: r};
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(_hifzRosterProvider(_class));
                    ref.invalidate(classHifzTodayProvider(_class));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: students.length,
                    separatorBuilder: (_, _) => const Gap(10),
                    itemBuilder: (_, i) {
                      final s = students[i];
                      final rec = byStudent[s.id];
                      return _RosterRow(
                        student: s,
                        record: rec,
                        onTap: () => _openLogSheet(s, rec),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(_hifzRosterProvider(_class)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLogSheet(StudentModel student, HifzRecord? existing) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HifzLogSheet(student: student, existing: existing),
    );
    if (saved == true) {
      ref.invalidate(classHifzTodayProvider(_class));
      ref.invalidate(studentHifzProvider(student.id));
    }
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.student, required this.record, required this.onTap});
  final StudentModel student;
  final HifzRecord? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logged = record != null;
    return AbmListRow(
      onTap: onTap,
      leading: abmInitialsAvatar(context, student.fullName),
      title: student.fullName,
      subtitle: logged ? 'Today: ${record!.sabaqLabel}' : 'Not logged today',
      trailing: logged
          ? AbmStatusPill(
              label: record!.quality.isEmpty ? 'Logged' : record!.quality,
              color: record!.quality.isEmpty ? colors.green : qualityColor(context, record!.quality))
          : Icon(LucideIcons.plusCircle, color: colors.primary, size: 20),
    );
  }
}

class _HifzLogSheet extends ConsumerStatefulWidget {
  const _HifzLogSheet({required this.student, this.existing});
  final StudentModel student;
  final HifzRecord? existing;

  @override
  ConsumerState<_HifzLogSheet> createState() => _HifzLogSheetState();
}

class _HifzLogSheetState extends ConsumerState<_HifzLogSheet> {
  late final _surah = TextEditingController(text: widget.existing?.sabaqSurah ?? '');
  late final _from = TextEditingController(text: widget.existing?.sabaqFrom ?? '');
  late final _to = TextEditingController(text: widget.existing?.sabaqTo ?? '');
  late final _sabqi = TextEditingController(text: widget.existing?.sabqi ?? '');
  late final _manzil = TextEditingController(text: widget.existing?.manzil ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late String _quality = widget.existing?.quality ?? '';
  bool _saving = false;

  @override
  void dispose() {
    _surah.dispose();
    _from.dispose();
    _to.dispose();
    _sabqi.dispose();
    _manzil.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(hifzRepositoryProvider).upsert(
            studentId: widget.student.id,
            sabaqSurah: _surah.text.trim(),
            sabaqFrom: _from.text.trim(),
            sabaqTo: _to.text.trim(),
            sabqi: _sabqi.text.trim(),
            manzil: _manzil.text.trim(),
            quality: _quality,
            notes: _notes.text.trim(),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: colors.border, borderRadius: BorderRadius.circular(2)))),
            const Gap(14),
            Text("Today's Hifz — ${widget.student.fullName}", style: context.typography.h4),
            const Gap(4),
            Text('Sabaq (new lesson)', style: context.typography.bodyMediumSemiBold.copyWith(color: colors.primary)),
            const Gap(8),
            ABMTextField(label: 'Surah', hint: 'e.g. Al-Baqarah', controller: _surah),
            const Gap(10),
            Row(children: [
              Expanded(child: ABMTextField(label: 'From', hint: 'ayah/line', controller: _from)),
              const Gap(10),
              Expanded(child: ABMTextField(label: 'To', hint: 'ayah/line', controller: _to)),
            ]),
            const Gap(14),
            ABMTextField(label: 'Sabqi (recent revision)', hint: 'e.g. Juz 3–4', controller: _sabqi),
            const Gap(10),
            ABMTextField(label: 'Manzil (old revision)', hint: 'e.g. Juz 1–2', controller: _manzil),
            const Gap(14),
            Text('Quality', style: context.typography.bodyMediumSemiBold),
            const Gap(8),
            Wrap(
              spacing: 8,
              children: _qualityOptions.map((q) {
                final sel = _quality == q;
                final c = qualityColor(context, q);
                return ChoiceChip(
                  label: Text(q),
                  selected: sel,
                  onSelected: (_) => setState(() => _quality = sel ? '' : q),
                  selectedColor: c.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: sel ? c : colors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
                );
              }).toList(),
            ),
            const Gap(14),
            ABMTextField(label: 'Notes (optional)', hint: 'Any remarks…', controller: _notes, maxLines: 2),
            const Gap(20),
            ABMButton(text: 'Save entry', isLoading: _saving, onPressed: _save),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
