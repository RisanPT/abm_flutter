import 'dart:convert';
import 'dart:typed_data';

import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/homework/data/homework_repository.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  final ScrollController _scrollController = ScrollController();
  String _classFilter = 'All';
  String _shiftFilter = 'All'; // 'All', 'Shift-1', 'Shift-2' — split two-batch classes
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Active', 'Overdue'
  int _page = 1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _canManage(String? role) => role != null &&
      role != AppRoles.student &&
      [
        AppRoles.teacher,
        AppRoles.headMaster,
        AppRoles.principal,
        AppRoles.itAdmin,
        AppRoles.superAdmin,
        AppRoles.staff,
      ].contains(role);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final user = ref.watch(authControllerProvider).value;
    final isStudent = user?.role == AppRoles.student;
    final canManage = _canManage(user?.role);
    // Students always see their own class (backend scopes it); staff can filter.
    final listKey = isStudent ? '' : _classFilter;
    final hwQuery = HomeworkQuery(classroom: listKey, shift: isStudent ? null : _shiftFilter, page: _page, instituteId: ref.watch(selectedInstituteProvider).id);
    final hwAsync = ref.watch(homeworkPageProvider(hwQuery));

    final classesAsync = ref.watch(classroomControllerProvider);
    final classOptions = classesAsync.maybeWhen(
      data: (classes) => ['All', ...classes.map((c) => c.name)],
      orElse: () => <String>['All'],
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Homework',
            subtitle: isStudent ? 'Assignments for your class' : 'Post and track class assignments',
            showBackButton: false,
            compact: true,
            actions: [
              if (canManage && !context.isMobile) ...[
                FilledButton.icon(
                  onPressed: () => _showForm(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('New Homework'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Gap(8),
              ],
              IconButton(
                onPressed: () {
                  ref.invalidate(homeworkPageProvider);
                  ref.invalidate(homeworkListProvider);
                },
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Homework',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeworkPageProvider);
                ref.invalidate(homeworkListProvider);
              },
              child: hwAsync.when(
                data: (pagedResult) {
                  final allItems = pagedResult.items;

                  // Compute KPIs
                  final now = DateTime.now();
                  int dueThisWeek = 0;
                  int overdueCount = 0;
                  final subjectSet = <String>{};

                  for (final item in allItems) {
                    if (item.subject.isNotEmpty) subjectSet.add(item.subject);
                    if (item.dueDate != null) {
                      final diff = item.dueDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
                      if (diff < 0) {
                        overdueCount++;
                      } else if (diff <= 7) {
                        dueThisWeek++;
                      }
                    }
                  }

                  // Apply client-side search & status filtering
                  final filtered = allItems.where((hw) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        hw.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        hw.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        hw.description.toLowerCase().contains(_searchQuery.toLowerCase());

                    bool matchesStatus = true;
                    if (_statusFilter == 'Active' && hw.dueDate != null) {
                      matchesStatus = hw.dueDate!.difference(DateTime(now.year, now.month, now.day)).inDays >= 0;
                    } else if (_statusFilter == 'Overdue' && hw.dueDate != null) {
                      matchesStatus = hw.dueDate!.difference(DateTime(now.year, now.month, now.day)).inDays < 0;
                    }

                    return matchesSearch && matchesStatus;
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
                              _HomeworkKpiCard(
                                title: 'Total Tasks',
                                value: '${pagedResult.total}',
                                subtext: '${subjectSet.length} subjects covered',
                                icon: LucideIcons.bookMarked,
                                color: const Color(0xFF2563EB),
                                badge: 'Assignments',
                              ),
                              _HomeworkKpiCard(
                                title: 'Due This Week',
                                value: '$dueThisWeek',
                                subtext: 'Upcoming deadlines',
                                icon: LucideIcons.calendarCheck,
                                color: const Color(0xFF059669),
                                badge: '$dueThisWeek Priority',
                              ),
                              _HomeworkKpiCard(
                                title: 'Past Deadline',
                                value: '$overdueCount',
                                subtext: overdueCount == 0 ? 'No overdue tasks' : 'Requires follow-up',
                                icon: LucideIcons.alertTriangle,
                                color: overdueCount == 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                badge: overdueCount == 0 ? 'Clear' : '$overdueCount Overdue',
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
                                        hintText: 'Search by title, subject, or description...',
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
                                  if (_searchQuery.isNotEmpty || _classFilter != 'All' || _shiftFilter != 'All' || _statusFilter != 'All') ...[
                                    const Gap(8),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _classFilter = 'All';
                                          _shiftFilter = 'All';
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
                                  if (canManage)
                                    SizedBox(
                                      width: 170,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _classFilter,
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
                                        items: classOptions
                                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _classFilter = val;
                                              _page = 1;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  if (canManage)
                                    SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment(value: 'All', label: Text('All Shifts', style: TextStyle(fontSize: 11))),
                                        ButtonSegment(value: 'Shift-1', label: Text('Shift-1', style: TextStyle(fontSize: 11))),
                                        ButtonSegment(value: 'Shift-2', label: Text('Shift-2', style: TextStyle(fontSize: 11))),
                                      ],
                                      selected: {_shiftFilter},
                                      onSelectionChanged: (set) => setState(() {
                                        _shiftFilter = set.first;
                                        _page = 1;
                                      }),
                                      style: const ButtonStyle(
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(value: 'All', label: Text('All Tasks', style: TextStyle(fontSize: 11))),
                                      ButtonSegment(value: 'Active', label: Text('Active', style: TextStyle(fontSize: 11))),
                                      ButtonSegment(value: 'Overdue', label: Text('Overdue', style: TextStyle(fontSize: 11))),
                                    ],
                                    selected: {_statusFilter},
                                    onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
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

                        // Header counts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              filtered.isEmpty
                                  ? 'No homework assignments'
                                  : 'Assignments (${filtered.length})',
                              style: typography.bodyMediumSemiBold,
                            ),
                            if (_classFilter != 'All')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Class: $_classFilter',
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
                                  child: Icon(LucideIcons.bookMarked, size: 36, color: colors.primary),
                                ),
                                const Gap(12),
                                Text('No assignments found', style: typography.bodyLargeSemiBold),
                                const Gap(6),
                                Text(
                                  isStudent
                                      ? 'No homework has been assigned for your selection.'
                                      : 'Try adjusting filters or tap "New Homework" to post one.',
                                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else ...[
                          for (final hw in filtered) ...[
                            _HomeworkCard(
                              hw: hw,
                              canManage: canManage,
                              isStudent: isStudent,
                              onToggleDone: (done) => _toggleDone(hw, done),
                              onEdit: () => _showForm(context, existing: hw),
                              onDelete: () => _delete(hw),
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
                                'Page ${pagedResult.page} of ${pagedResult.totalPages} · ${pagedResult.total} total items',
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
                  onRetry: () => ref.invalidate(homeworkPageProvider(hwQuery)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? (context.isMobile
              ? FloatingActionButton(
                  heroTag: 'addHomeworkFab',
                  onPressed: () => _showForm(context),
                  backgroundColor: colors.primary,
                  child: const Icon(LucideIcons.plus, color: Colors.white),
                )
              : FloatingActionButton.extended(
                  heroTag: 'addHomeworkFab',
                  onPressed: () => _showForm(context),
                  backgroundColor: colors.primary,
                  icon: const Icon(LucideIcons.plus, color: Colors.white),
                  label: const Text('Add homework', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ))
          : null,
    );
  }

  Future<void> _toggleDone(Homework hw, bool done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(homeworkRepositoryProvider).toggleComplete(hw.id, done);
      ref.invalidate(homeworkPageProvider);
      ref.invalidate(homeworkListProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _delete(Homework hw) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmActionDialog(
      context,
      title: 'Delete homework',
      message: 'Delete "${hw.title}"? This cannot be undone.',
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    try {
      await ref.read(homeworkRepositoryProvider).delete(hw.id);
      ref.invalidate(homeworkPageProvider);
      ref.invalidate(homeworkListProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Homework deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _showForm(BuildContext context, {Homework? existing}) async {
    final classesAsync = ref.read(classroomControllerProvider);
    final classes = classesAsync.maybeWhen(data: (c) => c.map((e) => e.name).toList(), orElse: () => <String>[]);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HomeworkForm(existing: existing, classes: classes),
    );
    if (saved == true) {
      ref.invalidate(homeworkPageProvider);
      ref.invalidate(homeworkListProvider);
    }
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({
    required this.hw,
    required this.canManage,
    required this.isStudent,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
  });

  final Homework hw;
  final bool canManage;
  final bool isStudent;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    // Due-date chip colour: overdue = red, due within 2 days = amber, else normal.
    Widget? dueChip;
    if (hw.dueDate != null) {
      final now = DateTime.now();
      final due = hw.dueDate!;
      final days = due.difference(DateTime(now.year, now.month, now.day)).inDays;
      Color c;
      String label;
      if (days < 0) {
        c = colors.red;
        label = 'Overdue · ${DateFormat('dd MMM').format(due)}';
      } else if (days <= 2) {
        c = colors.warning;
        label = 'Due ${DateFormat('dd MMM').format(due)}';
      } else {
        c = colors.textSecondary;
        label = 'Due ${DateFormat('dd MMM').format(due)}';
      }
      dueChip = AbmStatusPill(label: label, color: c, icon: LucideIcons.calendar);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hw.subject.isNotEmpty) ...[
                          _Tag(text: hw.subject, color: colors.primary),
                          const Gap(6),
                        ],
                        _Tag(text: hw.classroom, color: colors.secondary),
                        if (hw.shift.isNotEmpty && hw.shift != 'All') ...[
                          const Gap(6),
                          _Tag(text: hw.shift, color: colors.primary),
                        ],
                      ],
                    ),
                    const Gap(8),
                    Text(hw.title, style: t.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical, size: 18, color: colors.textSecondary),
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          if (hw.description.isNotEmpty) ...[
            const Gap(6),
            Text(hw.description, style: t.bodyMedium.copyWith(color: colors.textSecondary)),
          ],
          const Gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ?dueChip,
              if (hw.assignedByName.isNotEmpty)
                Text('by ${hw.assignedByName}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
              if (hw.hasAttachment)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(hw.attachmentUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(LucideIcons.paperclip, size: 15),
                  label: const Text('Attachment'),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 32)),
                ),
              if (canManage && !isStudent)
                Text('${hw.completedCount} done', style: t.bodySmall.copyWith(color: colors.green)),
            ],
          ),
          if (isStudent) ...[
            const Divider(height: 20),
            InkWell(
              onTap: () => onToggleDone(!hw.completed),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(hw.completed ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: hw.completed ? colors.green : colors.textSecondary, size: 20),
                  const Gap(8),
                  Text(hw.completed ? 'Done' : 'Mark as done',
                      style: t.bodyMediumSemiBold.copyWith(
                          color: hw.completed ? colors.green : colors.textPrimary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: context.typography.bodySmallSemiBold.copyWith(color: color)),
      );
}

class _HomeworkKpiCard extends StatelessWidget {
  const _HomeworkKpiCard({
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

/// Add / edit homework form (bottom sheet).
class _HomeworkForm extends ConsumerStatefulWidget {
  const _HomeworkForm({this.existing, required this.classes});
  final Homework? existing;
  final List<String> classes;

  @override
  ConsumerState<_HomeworkForm> createState() => _HomeworkFormState();
}

class _HomeworkFormState extends ConsumerState<_HomeworkForm> {
  late final TextEditingController _title = TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _subject = TextEditingController(text: widget.existing?.subject ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.existing?.description ?? '');
  late String? _classroom = widget.existing?.classroom;
  late String _shift = widget.existing?.shift ?? 'All'; // target batch
  late DateTime? _dueDate = widget.existing?.dueDate;
  Uint8List? _imageBytes;
  String _imageName = '';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1400);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (mounted) setState(() { _imageBytes = bytes; _imageName = f.name; });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if ((_classroom == null || _classroom!.isEmpty)) {
      messenger.showSnackBar(const SnackBar(content: Text('Please choose a class.')));
      return;
    }
    if (_title.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Please add a title.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(homeworkRepositoryProvider);
      if (widget.existing == null) {
        String? attachment;
        if (_imageBytes != null) {
          final mime = _imageName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
          attachment = 'data:$mime;base64,${base64Encode(_imageBytes!)}';
        }
        await repo.create(
          classroom: _classroom!,
          shift: _shift,
          title: _title.text.trim(),
          subject: _subject.text.trim(),
          description: _desc.text.trim(),
          dueDate: _dueDate,
          attachment: attachment,
          instituteId: ref.read(selectedInstituteProvider).id,
        );
      } else {
        await repo.update(
          widget.existing!.id,
          classroom: _classroom,
          shift: _shift,
          title: _title.text.trim(),
          subject: _subject.text.trim(),
          description: _desc.text.trim(),
          dueDate: _dueDate,
        );
      }
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
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: colors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const Gap(14),
            Text(isEdit ? 'Edit homework' : 'Add homework', style: context.typography.h4),
            const Gap(16),
            DropdownButtonFormField<String>(
              initialValue: (_classroom != null && widget.classes.contains(_classroom)) ? _classroom : null,
              decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
              items: widget.classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _classroom = v),
            ),
            const Gap(12),
            DropdownButtonFormField<String>(
              initialValue: _shift,
              decoration: const InputDecoration(labelText: 'For (batch / shift)', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('Whole class (all shifts)')),
                DropdownMenuItem(value: 'Shift-1', child: Text('Shift-1 only')),
                DropdownMenuItem(value: 'Shift-2', child: Text('Shift-2 only')),
              ],
              onChanged: (v) => setState(() => _shift = v ?? 'All'),
            ),
            const Gap(12),
            ABMTextField(label: 'Title', hint: 'e.g. Read Surah Al-Mulk', controller: _title),
            const Gap(12),
            ABMTextField(label: 'Subject (optional)', hint: 'e.g. Hifz', controller: _subject),
            const Gap(12),
            ABMTextField(label: 'Details (optional)', hint: 'Instructions…', controller: _desc, maxLines: 3),
            const Gap(12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due date', border: OutlineInputBorder()),
                child: Text(_dueDate == null ? 'Pick a date' : DateFormat('EEE, dd MMM yyyy').format(_dueDate!),
                    style: context.typography.bodyMedium),
              ),
            ),
            if (!isEdit) ...[
              const Gap(12),
              if (_imageBytes == null)
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(LucideIcons.imagePlus, size: 18),
                  label: const Text('Attach a photo (optional)'),
                )
              else
                Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, width: 48, height: 48, fit: BoxFit.cover)),
                  const Gap(10),
                  Expanded(child: Text(_imageName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.typography.bodySmall)),
                  IconButton(onPressed: () => setState(() { _imageBytes = null; _imageName = ''; }),
                      icon: Icon(LucideIcons.x, size: 18, color: colors.red)),
                ]),
            ],
            const Gap(20),
            ABMButton(text: isEdit ? 'Save changes' : 'Post homework', isLoading: _saving, onPressed: _save),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
