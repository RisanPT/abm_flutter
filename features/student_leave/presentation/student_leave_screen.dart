import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/student_leave/data/student_leave_repository.dart';
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

String _range(StudentLeave l) {
  if (l.fromDate == null) return '';
  final f = DateFormat('dd MMM').format(l.fromDate!.toLocal());
  final t = l.toDate != null ? DateFormat('dd MMM yyyy').format(l.toDate!.toLocal()) : '';
  return l.fromDate == l.toDate ? DateFormat('dd MMM yyyy').format(l.fromDate!.toLocal()) : '$f – $t';
}

// ─── Student view ────────────────────────────────────────────────────────────

class _StudentLeaveView extends ConsumerWidget {
  const _StudentLeaveView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(myLeavesProvider);
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(title: 'My Leave', subtitle: 'Request and track leave', height: context.isMobile ? 160 : 180),
          Expanded(
            child: async.when(
              data: (items) => items.isEmpty
                  ? const AbmEmptyState(icon: LucideIcons.calendarOff, title: 'No leave requests', message: 'Tap "Request leave" to submit one.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Gap(10),
                      itemBuilder: (_, i) => _LeaveCard(leave: items[i], staff: false),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(message: friendlyErrorMessage(e), onRetry: () => ref.invalidate(myLeavesProvider)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _request(context, ref),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Request leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      messenger.showSnackBar(const SnackBar(content: Text('Pick the from and to dates.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(studentLeaveRepositoryProvider).submit(fromDate: _from!, toDate: _to!, reason: _reason.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) { setState(() => _saving = false); messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e)))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget dateField(String label, DateTime? value, bool from) => Expanded(
          child: InkWell(
            onTap: () => _pick(from),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
              child: Text(value == null ? 'Pick' : DateFormat('dd MMM yyyy').format(value), style: context.typography.bodyMedium),
            ),
          ),
        );
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)))),
          const Gap(14),
          Text('Request leave', style: context.typography.h4),
          const Gap(16),
          Row(children: [dateField('From', _from, true), const Gap(12), dateField('To', _to, false)]),
          const Gap(12),
          ABMTextField(label: 'Reason', hint: 'e.g. Family travel', controller: _reason, maxLines: 2),
          const Gap(18),
          ABMButton(text: 'Submit request', isLoading: _saving, onPressed: _save),
          const Gap(8),
        ],
      ),
    );
  }
}

// ─── Staff view ──────────────────────────────────────────────────────────────

class _StaffLeaveView extends ConsumerStatefulWidget {
  const _StaffLeaveView();
  @override
  ConsumerState<_StaffLeaveView> createState() => _StaffLeaveViewState();
}

class _StaffLeaveViewState extends ConsumerState<_StaffLeaveView> {
  String _status = 'Pending';
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final leaveQuery = StudentLeaveQuery(status: _status, page: _page);
    final async = ref.watch(staffLeavesPageProvider(leaveQuery));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(title: 'Student Leave', subtitle: 'Approve or reject leave requests', height: context.isMobile ? 160 : 180),
          Container(
            color: colors.background,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: ['Pending', 'Approved', 'Rejected', 'All'].map((s) {
                final sel = s == _status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _status = s;
                      _page = 1;
                    }),
                    selectedColor: colors.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: sel ? colors.primary : colors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(staffLeavesPageProvider);
                ref.invalidate(staffLeavesProvider);
              },
              child: async.when(
                data: (pagedResult) {
                  final items = pagedResult.items;
                  if (items.isEmpty) {
                    return ListView(children: [const Gap(60), AbmEmptyState(icon: LucideIcons.calendarCheck2, title: 'No $_status requests')]);
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Gap(10),
                          itemBuilder: (_, i) => _LeaveCard(
                            leave: items[i],
                            staff: true,
                            onDecide: (status) => _decide(items[i], status),
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
                  ref.invalidate(staffLeavesPageProvider);
                  ref.invalidate(staffLeavesProvider);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _decide(StudentLeave leave, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$status leave'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${leave.studentName} · ${_range(leave)}', style: context.typography.bodySmall),
          const Gap(12),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'Approved' ? context.colors.green : context.colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(status),
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
      ref.invalidate(staffLeavesProvider(_status));
      messenger.showSnackBar(SnackBar(content: Text('Leave $status.'.toLowerCase())));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave, required this.staff, this.onDecide});
  final StudentLeave leave;
  final bool staff;
  final ValueChanged<String>? onDecide;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(staff ? '${leave.studentName} · ${leave.classroom}' : _range(leave), style: t.bodyMediumSemiBold)),
            AbmStatusPill.status(context, leave.status),
          ]),
          if (staff) ...[const Gap(4), Text(_range(leave), style: t.bodySmall.copyWith(color: colors.textSecondary))],
          if (leave.reason.isNotEmpty) ...[const Gap(6), Text(leave.reason, style: t.bodyMedium.copyWith(color: colors.textSecondary))],
          if (leave.decisionNote.isNotEmpty) ...[
            const Gap(6),
            Text('Note: ${leave.decisionNote}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
          ],
          if (staff && leave.status == 'Pending' && onDecide != null) ...[
            const Gap(12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => onDecide!('Rejected'),
                icon: const Icon(LucideIcons.x, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: colors.red),
              )),
              const Gap(10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => onDecide!('Approved'),
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(backgroundColor: colors.green, foregroundColor: Colors.white),
              )),
            ]),
          ],
        ],
      ),
    );
  }
}
