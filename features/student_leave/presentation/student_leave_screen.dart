import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/student_leave/data/student_leave_repository.dart';
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

class StudentLeaveScreen extends ConsumerWidget {
  const StudentLeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user?.role == AppRoles.student) return const _StudentLeaveView();
    return const _StaffLeaveView();
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _range(StudentLeave l) {
  if (l.fromDate == null) return '';
  final from = l.fromDate!.toLocal();
  final to = l.toDate?.toLocal() ?? from;
  final f = DateFormat('dd MMM yyyy').format(from);
  final t = DateFormat('dd MMM yyyy').format(to);
  if (from.year == to.year && from.month == to.month && from.day == to.day) {
    return f;
  }
  return '$f  –  $t';
}

int _durationDays(StudentLeave l) {
  if (l.fromDate == null) return 0;
  final from = DateUtils.dateOnly(l.fromDate!.toLocal());
  final to = DateUtils.dateOnly((l.toDate ?? l.fromDate!).toLocal());
  final diff = to.difference(from).inDays + 1;
  return diff > 0 ? diff : 1;
}

String _getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts[0].isEmpty) return '?';
  if (parts.length == 1) {
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

// ─── Staff View ──────────────────────────────────────────────────────────────

class _StaffLeaveView extends ConsumerStatefulWidget {
  const _StaffLeaveView();

  @override
  ConsumerState<_StaffLeaveView> createState() => _StaffLeaveViewState();
}

class _StaffLeaveViewState extends ConsumerState<_StaffLeaveView> {
  String _status = 'Pending';
  String? _selectedClassroom;
  String _searchQuery = '';
  int _page = 1;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = context.isDesktop;
    final leaveQuery = StudentLeaveQuery(
      status: _status,
      classroom: _selectedClassroom == 'All' ? null : _selectedClassroom,
      page: _page,
    );
    final async = ref.watch(staffLeavesPageProvider(leaveQuery));
    final allLeavesAsync = ref.watch(staffLeavesProvider('All'));
    final classroomsAsync = ref.watch(classroomControllerProvider);

    // Compute summary metrics from allLeavesAsync
    final allList = allLeavesAsync.value ?? [];
    final pendingCount = allList.where((l) => l.status == 'Pending').length;
    final approvedCount = allList.where((l) => l.status == 'Approved').length;
    final rejectedCount = allList.where((l) => l.status == 'Rejected').length;
    final totalCount = allList.length;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Student Leave',
            subtitle: 'Review, approve, and track student leave requests',
            height: context.isMobile ? 150 : 170,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(staffLeavesPageProvider);
                ref.invalidate(staffLeavesProvider);
              },
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 16,
                ),
                children: [
                  // ─── Stats KPI Overview ─────────────────────────────
                  _buildStatCardsRow(
                    context,
                    pending: pendingCount,
                    approved: approvedCount,
                    rejected: rejectedCount,
                    total: totalCount,
                  ),
                  const Gap(16),

                  // ─── Filters & Search Toolbar ───────────────────────
                  _buildFilterBar(
                    context,
                    pendingCount: pendingCount,
                    approvedCount: approvedCount,
                    rejectedCount: rejectedCount,
                    totalCount: totalCount,
                    classrooms: classroomsAsync.value ?? [],
                  ),
                  const Gap(16),

                  // ─── Leave Requests List ────────────────────────────
                  async.when(
                    data: (pagedResult) {
                      var items = pagedResult.items;

                      // Client-side search filtering by student name or reason
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        items = items.where((l) {
                          return l.studentName.toLowerCase().contains(q) ||
                              l.reason.toLowerCase().contains(q) ||
                              l.classroom.toLowerCase().contains(q);
                        }).toList();
                      }

                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: AbmEmptyState(
                            icon: LucideIcons.calendarCheck2,
                            title: _searchQuery.isNotEmpty
                                ? 'No matching leave requests'
                                : 'No $_status leave requests',
                            message: _searchQuery.isNotEmpty
                                ? 'Try searching with a different name or keyword.'
                                : 'All clear! No student leave requests in this category.',
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const Gap(12),
                            itemBuilder: (_, i) => _LeaveCard(
                              leave: items[i],
                              staff: true,
                              onDecide: (status) => _decide(items[i], status),
                            ),
                          ),
                          if (pagedResult.totalPages > 1 && _searchQuery.isEmpty) ...[
                            const Gap(20),
                            AbmPaginationBar(
                              page: pagedResult.page,
                              totalPages: pagedResult.totalPages,
                              total: pagedResult.total,
                              onPage: (p) => setState(() => _page = p),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => AbmErrorView(
                      message: friendlyErrorMessage(e),
                      onRetry: () {
                        ref.invalidate(staffLeavesPageProvider);
                        ref.invalidate(staffLeavesProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardsRow(
    BuildContext context, {
    required int pending,
    required int approved,
    required int rejected,
    required int total,
  }) {
    final colors = context.colors;
    final isDesktop = context.isDesktop;

    final cards = [
      _StatCard(
        label: 'Pending Review',
        count: pending,
        icon: LucideIcons.clock,
        accentColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        isSelected: _status == 'Pending',
        onTap: () => setState(() {
          _status = 'Pending';
          _page = 1;
        }),
      ),
      _StatCard(
        label: 'Approved',
        count: approved,
        icon: LucideIcons.checkCircle2,
        accentColor: const Color(0xFF16A34A),
        bgColor: const Color(0xFFF0FDF4),
        isSelected: _status == 'Approved',
        onTap: () => setState(() {
          _status = 'Approved';
          _page = 1;
        }),
      ),
      _StatCard(
        label: 'Rejected',
        count: rejected,
        icon: LucideIcons.xCircle,
        accentColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        isSelected: _status == 'Rejected',
        onTap: () => setState(() {
          _status = 'Rejected';
          _page = 1;
        }),
      ),
      _StatCard(
        label: 'Total Requests',
        count: total,
        icon: LucideIcons.calendarCheck,
        accentColor: colors.primary,
        bgColor: colors.primary.withValues(alpha: 0.06),
        isSelected: _status == 'All',
        onTap: () => setState(() {
          _status = 'All';
          _page = 1;
        }),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: card,
                  ),
                ))
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(width: 140, child: card),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context, {
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required int totalCount,
    required List<dynamic> classrooms,
  }) {
    final colors = context.colors;
    final isDesktop = context.isDesktop;

    int countFor(String s) {
      switch (s) {
        case 'Pending':
          return pendingCount;
        case 'Approved':
          return approvedCount;
        case 'Rejected':
          return rejectedCount;
        default:
          return totalCount;
      }
    }

    final chips = ['Pending', 'Approved', 'Rejected', 'All'].map((s) {
      final sel = s == _status;
      final count = countFor(s);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () => setState(() {
            _status = s;
            _page = 1;
          }),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? colors.primary : colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? colors.primary : colors.border,
                width: 1.2,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s,
                  style: TextStyle(
                    color: sel ? Colors.white : colors.textPrimary,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: sel
                          ? Colors.white.withValues(alpha: 0.25)
                          : colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: sel ? Colors.white : colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();

    final searchField = Container(
      width: isDesktop ? 220 : double.infinity,
      height: 38,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search student or reason...',
          hintStyle: TextStyle(fontSize: 12, color: colors.textSecondary),
          prefixIcon: Icon(LucideIcons.search, size: 15, color: colors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 13),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        ),
      ),
    );

    final classroomDropdown = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassroom ?? 'All',
          icon: Icon(LucideIcons.chevronDown, size: 15, color: colors.textSecondary),
          style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w500),
          items: [
            const DropdownMenuItem(value: 'All', child: Text('All Classes')),
            ...classrooms.map((c) {
              final name = c.name as String;
              return DropdownMenuItem(value: name, child: Text(name));
            }),
          ],
          onChanged: (val) => setState(() {
            _selectedClassroom = val == 'All' ? null : val;
            _page = 1;
          }),
        ),
      ),
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            ...chips,
            const Spacer(),
            classroomDropdown,
            const SizedBox(width: 10),
            searchField,
          ],
        ),
      );
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chips),
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 8),
            classroomDropdown,
          ],
        ),
      ],
    );
  }

  Future<void> _decide(StudentLeave leave, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final noteCtrl = TextEditingController();
    final isApprove = status == 'Approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isApprove
                    ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                    : const Color(0xFFDC2626).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApprove ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                size: 20,
                color: isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$status Leave Request',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(ctx).primaryColor.withValues(alpha: 0.15),
                    child: Text(
                      _getInitials(leave.studentName),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(ctx).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          '${leave.classroom.isNotEmpty ? '${leave.classroom} • ' : ''}${_range(leave)} (${_durationDays(leave)} ${_durationDays(leave) == 1 ? 'day' : 'days'})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(14),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Decision remark / note (optional)',
                hintText: isApprove ? 'e.g. Approved by Principal' : 'e.g. Medical certificate required',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const Gap(8),
            Wrap(
              spacing: 6,
              children: [
                if (isApprove) ...[
                  _quickChip(noteCtrl, 'Approved'),
                  _quickChip(noteCtrl, 'Medical leave noted'),
                  _quickChip(noteCtrl, 'Family leave granted'),
                ] else ...[
                  _quickChip(noteCtrl, 'Insufficient reason'),
                  _quickChip(noteCtrl, 'Exam period - leave denied'),
                  _quickChip(noteCtrl, 'Exceeded leave allowance'),
                ],
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isApprove ? 'Approve' : 'Reject',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (confirmed != true) return;

    try {
      await ref.read(studentLeaveRepositoryProvider).decide(leave.id, status: status, note: note);
      ref.invalidate(staffLeavesPageProvider);
      ref.invalidate(staffLeavesProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isApprove ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text('Leave request marked as $status.'),
            ],
          ),
          backgroundColor: isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Widget _quickChip(TextEditingController ctrl, String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        ctrl.text = text;
      },
    );
  }
}

// ─── Stat Card Widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : colors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? accentColor : colors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leave Card Widget ───────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.leave,
    required this.staff,
    this.onDecide,
  });

  final StudentLeave leave;
  final bool staff;
  final ValueChanged<String>? onDecide;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPending = leave.status == 'Pending';
    final isApproved = leave.status == 'Approved';
    final days = _durationDays(leave);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFD97706).withValues(alpha: 0.3)
              : colors.border,
          width: isPending ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Card Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (staff) ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    child: Text(
                      _getInitials(leave.studentName),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff ? leave.studentName : 'Leave Request',
                        style: context.typography.bodyMediumSemiBold.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (staff && leave.classroom.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.graduationCap, size: 11, color: colors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    leave.classroom,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (leave.createdAt != null)
                            Text(
                              'Applied ${DateFormat('dd MMM yyyy').format(leave.createdAt!.toLocal())}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _statusBadge(context, leave.status),
              ],
            ),
          ),

          // ─── Leave Dates & Duration Strip ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 14, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _range(leave),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '$days ${days == 1 ? 'Day' : 'Days'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Reason Section ───────────────────────────────────────
          if (leave.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.messageSquare,
                      size: 13,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leave.reason,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Decision Note Section (if reviewed) ──────────────────
          if (leave.decisionNote.isNotEmpty || leave.decidedByName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFF16A34A).withValues(alpha: 0.06)
                      : const Color(0xFFDC2626).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isApproved
                        ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                        : const Color(0xFFDC2626).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isApproved ? LucideIcons.checkCheck : LucideIcons.alertCircle,
                      size: 14,
                      color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (leave.decidedByName.isNotEmpty)
                            Text(
                              'Reviewed by ${leave.decidedByName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          if (leave.decisionNote.isNotEmpty)
                            Text(
                              leave.decisionNote,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Staff Action Buttons (when Pending) ──────────────────
          if (staff && isPending && onDecide != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.border.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onDecide!('Rejected'),
                    icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.04),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => onDecide!('Approved'),
                    icon: const Icon(LucideIcons.check, size: 14, color: Colors.white),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Gap(14),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label = status;

    switch (status) {
      case 'Approved':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF16A34A);
        icon = LucideIcons.checkCircle2;
        break;
      case 'Rejected':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFDC2626);
        icon = LucideIcons.xCircle;
        break;
      case 'Pending':
      default:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFD97706);
        icon = LucideIcons.clock;
        label = 'Pending Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Student View ────────────────────────────────────────────────────────────

class _StudentLeaveView extends ConsumerWidget {
  const _StudentLeaveView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(myLeavesProvider);
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'My Leave',
            subtitle: 'Request and track your leave history',
            height: context.isMobile ? 150 : 170,
          ),
          Expanded(
            child: async.when(
              data: (items) => items.isEmpty
                  ? const Center(
                      child: AbmEmptyState(
                        icon: LucideIcons.calendarOff,
                        title: 'No leave requests yet',
                        message: 'Need time off? Tap "Request leave" below to submit a request.',
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 16,
                        16,
                        isDesktop ? 24 : 16,
                        96,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Gap(12),
                      itemBuilder: (_, i) => _LeaveCard(leave: items[i], staff: false),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(
                message: friendlyErrorMessage(e),
                onRetry: () => ref.invalidate(myLeavesProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _request(context, ref),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Request leave',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _RequestLeaveSheet(),
    );
    if (ok == true) ref.invalidate(myLeavesProvider);
  }
}

class _RequestLeaveSheet extends ConsumerStatefulWidget {
  const _RequestLeaveSheet();

  @override
  ConsumerState<_RequestLeaveSheet> createState() => _RequestLeaveSheetState();
}

class _RequestLeaveSheetState extends ConsumerState<_RequestLeaveSheet> {
  DateTime? _from;
  DateTime? _to;
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _from = picked;
          if (_to != null && _to!.isBefore(picked)) _to = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_from == null || _to == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please pick both from and to dates.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(studentLeaveRepositoryProvider).submit(
            fromDate: _from!,
            toDate: _to!,
            reason: _reason.text.trim(),
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
    final int days = (_from != null && _to != null)
        ? _to!.difference(_from!).inDays + 1
        : 0;

    Widget dateField(String label, DateTime? value, bool from) => Expanded(
          child: InkWell(
            onTap: () => _pick(from),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(LucideIcons.calendar, size: 16),
                isDense: true,
              ),
              child: Text(
                value == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(value),
                style: context.typography.bodyMedium.copyWith(
                  fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.calendarPlus, size: 18, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Text('Request Student Leave', style: context.typography.h4),
            ],
          ),
          const Gap(18),
          Row(
            children: [
              dateField('From Date', _from, true),
              const Gap(12),
              dateField('To Date', _to, false),
            ],
          ),
          if (days > 0) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Selected duration: $days ${days == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Gap(14),
          ABMTextField(
            label: 'Reason for leave',
            hint: 'e.g. Family function, medical rest, travel...',
            controller: _reason,
            maxLines: 2,
          ),
          const Gap(8),
          Wrap(
            spacing: 6,
            children: [
              'Medical / Illness',
              'Family Function',
              'Out of Town',
              'Personal Emergency',
            ].map((preset) {
              return ActionChip(
                label: Text(preset, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _reason.text = preset;
                },
              );
            }).toList(),
          ),
          const Gap(20),
          ABMButton(
            text: 'Submit leave request',
            isLoading: _saving,
            onPressed: _save,
          ),
          const Gap(8),
        ],
      ),
    );
  }
}
