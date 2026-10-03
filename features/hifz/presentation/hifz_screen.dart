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
  final ScrollController _scrollController = ScrollController();
  String _class = 'All';
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Logged', 'Pending'
  int _page = 1;
  static const int _pageSize = 10;

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
            showBackButton: false,
            compact: true,
            actions: [
              IconButton(
                onPressed: () {
                  ref.invalidate(_hifzRosterProvider(_class));
                  ref.invalidate(classHifzTodayProvider(_class));
                },
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Roster',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Expanded(
            child: rosterAsync.when(
              data: (allStudents) {
                final today = todayAsync.value ?? const <HifzRecord>[];
                final byStudent = {for (final r in today) r.studentId: r};

                final loggedCount = allStudents.where((s) => byStudent.containsKey(s.id)).length;
                final pendingCount = allStudents.length - loggedCount;
                final completionRate = allStudents.isNotEmpty ? ((loggedCount / allStudents.length) * 100).toInt() : 0;

                // Apply Search & Status filters
                final filtered = allStudents.where((s) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      s.admissionNumber.toLowerCase().contains(_searchQuery.toLowerCase());

                  final isLogged = byStudent.containsKey(s.id);
                  final matchesStatus = _statusFilter == 'All' ||
                      (_statusFilter == 'Logged' && isLogged) ||
                      (_statusFilter == 'Pending' && !isLogged);

                  return matchesSearch && matchesStatus;
                }).toList();

                // Pagination
                final totalCount = filtered.length;
                final totalPages = totalCount == 0 ? 1 : (totalCount / _pageSize).ceil();
                final effectivePage = _page.clamp(1, totalPages);
                final startIndex = totalCount == 0 ? 0 : (effectivePage - 1) * _pageSize;
                final endIndex = (startIndex + _pageSize).clamp(0, totalCount);
                final pagedStudents = totalCount == 0 ? <StudentModel>[] : filtered.sublist(startIndex, endIndex);

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
                            _HifzKpiCard(
                              title: 'Total Enrolled',
                              value: '${allStudents.length}',
                              subtext: _class == 'All' ? 'All Classes' : 'Class $_class',
                              icon: LucideIcons.users,
                              color: const Color(0xFF2563EB),
                              badge: 'Class Roster',
                            ),
                            _HifzKpiCard(
                              title: 'Logged Today',
                              value: '$loggedCount',
                              subtext: '$completionRate% completed today',
                              icon: LucideIcons.checkCircle2,
                              color: const Color(0xFF059669),
                              badge: '$completionRate% Done',
                            ),
                            _HifzKpiCard(
                              title: 'Pending Log',
                              value: '$pendingCount',
                              subtext: pendingCount == 0 ? 'All students logged' : 'Awaiting today recitation',
                              icon: LucideIcons.clock,
                              color: pendingCount == 0 ? const Color(0xFF059669) : const Color(0xFFD97706),
                              badge: pendingCount == 0 ? 'Complete' : '$pendingCount Remaining',
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

                      // Filter & Search Toolbar
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
                                    onChanged: (val) => setState(() {
                                      _searchQuery = val.trim();
                                      _page = 1;
                                    }),
                                    decoration: InputDecoration(
                                      hintText: 'Search by student name or admission ID...',
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
                                if (_searchQuery.isNotEmpty || _class != 'All' || _statusFilter != 'All') ...[
                                  const Gap(8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _class = 'All';
                                        _statusFilter = 'All';
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
                                // Class dropdown
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
                                // Segmented Status Button
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(value: 'All', label: Text('All Students', style: TextStyle(fontSize: 11))),
                                    ButtonSegment(value: 'Logged', label: Text('Logged', style: TextStyle(fontSize: 11))),
                                    ButtonSegment(value: 'Pending', label: Text('Pending', style: TextStyle(fontSize: 11))),
                                  ],
                                  selected: {_statusFilter},
                                  onSelectionChanged: (set) => setState(() {
                                    _statusFilter = set.first;
                                    _page = 1;
                                  }),
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                            totalCount == 0
                                ? 'No students found'
                                : 'Showing ${startIndex + 1}–$endIndex of $totalCount Students',
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
                                child: Icon(LucideIcons.users, size: 36, color: colors.primary),
                              ),
                              const Gap(12),
                              Text('No matching students', style: typography.bodyLargeSemiBold),
                              const Gap(6),
                              Text(
                                'Try clearing search or picking another class filter.',
                                style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else ...[
                        for (final s in pagedStudents) ...[
                          _RosterRow(
                            student: s,
                            record: byStudent[s.id],
                            onTap: () => _openLogSheet(s, byStudent[s.id]),
                          ),
                          const Gap(10),
                        ],
                        if (totalPages > 1) ...[
                          const Gap(10),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: AbmPaginationBar(
                                page: effectivePage,
                                totalPages: totalPages,
                                total: totalCount,
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
                              'Showing ${startIndex + 1}–$endIndex of $totalCount students · $_pageSize per page',
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

class _HifzKpiCard extends StatelessWidget {
  const _HifzKpiCard({
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

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.student, required this.record, required this.onTap});
  final StudentModel student;
  final HifzRecord? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final logged = record != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: logged ? colors.green.withValues(alpha: 0.3) : colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: logged ? colors.green.withValues(alpha: 0.12) : colors.primary.withValues(alpha: 0.08),
                  child: Text(
                    student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                    style: TextStyle(
                      color: logged ? colors.green : colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              student.fullName,
                              style: typography.bodyMediumSemiBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(6),
                          if (student.classroom.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                student.classroom,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                        ],
                      ),
                      const Gap(4),
                      if (logged) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.bookOpen, size: 11, color: Color(0xFF047857)),
                                  const Gap(4),
                                  Text(
                                    record!.sabaqLabel == '—' ? 'Sabaq recorded' : record!.sabaqLabel,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ],
                              ),
                            ),
                            if (record!.sabqi.isNotEmpty)
                              Text('Sabqi: ${record!.sabqi}', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                            if (record!.manzil.isNotEmpty)
                              Text('· Manzil: ${record!.manzil}', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                            Text('Not logged today', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(10),
                if (logged) ...[
                  if (record!.quality.isNotEmpty)
                    AbmStatusPill(
                      label: record!.quality,
                      color: qualityColor(context, record!.quality),
                    ),
                  const Gap(6),
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 16),
                    onPressed: onTap,
                    tooltip: 'Edit Today Entry',
                    visualDensity: VisualDensity.compact,
                  ),
                ] else ...[
                  FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Log Sabaq', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
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
