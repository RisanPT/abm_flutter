import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/attendance/data/staff_checkin_repository.dart';
import 'package:abm_madrasa/features/attendance/domain/staff_checkin_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _green = Color(0xFF0F4A3A);
const _gold = Color(0xFFD6B64C);
const _present = Color(0xFF2F855A);
const _late = Color(0xFFDD6B20);
const _absent = Color(0xFFC53030);

Color _statusColor(String s) => switch (s) {
      'Present' => _present,
      'Late' => _late,
      _ => _absent,
    };

class StaffCheckinScreen extends ConsumerWidget {
  const StaffCheckinScreen({super.key});

  Future<void> _checkIn(BuildContext context, WidgetRef ref, {String status = 'Present'}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(staffCheckinRepositoryProvider).checkIn(status: status);
      ref.invalidate(myCheckinProvider);
      messenger.showSnackBar(SnackBar(content: Text('Checked in — $status'), backgroundColor: _present));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _absent,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(myCheckinProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _header(context, user?.username ?? ''),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _green)),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(e.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
              data: (s) => RefreshIndicator(
                color: _green,
                onRefresh: () async => ref.invalidate(myCheckinProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _checkinCard(context, ref, s),
                    const Gap(20),
                    Text('This month', style: context.typography.bodyLargeSemiBold),
                    const Gap(4),
                    if (s.records.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No check-ins yet this month.',
                            style: TextStyle(color: colors.textSecondary)),
                      )
                    else
                      ...s.records.map((r) => _historyRow(context, r)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String name) {
    final typography = context.typography;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCheck, color: _gold, size: 22),
              const Gap(10),
              Text('My Attendance', style: typography.h3.copyWith(color: Colors.white)),
            ],
          ),
          const Gap(4),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: typography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _checkinCard(BuildContext context, WidgetRef ref, MyCheckinSummary s) {
    final typography = context.typography;
    if (s.checkedInToday) {
      final color = _statusColor(s.todayStatus ?? 'Present');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: color, size: 34),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You're checked in today", style: typography.bodyLargeSemiBold),
                  const Gap(2),
                  Text('Marked ${s.todayStatus ?? 'Present'} · ${s.presentDays} present days this month',
                      style: typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _checkIn(context, ref, status: s.todayStatus == 'Late' ? 'Present' : 'Late'),
              child: Text(s.todayStatus == 'Late' ? 'Mark Present' : 'Mark Late'),
            ),
          ],
        ),
      );
    }

    // Not checked in yet — the big primary action.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You haven’t checked in today', style: typography.bodyLargeSemiBold),
          const Gap(4),
          Text('Mark your attendance for ${DateFormat('EEE, dd MMM').format(DateTime.now())}.',
              style: typography.bodySmall.copyWith(color: context.colors.textSecondary)),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _checkIn(context, ref, status: 'Present'),
              icon: const Icon(LucideIcons.check, size: 20),
              label: const Text('Check in for today'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: typography.bodyLargeSemiBold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Gap(8),
          Center(
            child: TextButton(
              onPressed: () => _checkIn(context, ref, status: 'Late'),
              child: const Text('Check in as Late'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(BuildContext context, StaffCheckin r) {
    final color = _statusColor(r.status);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const Gap(12),
          Expanded(
            child: Text(DateFormat('EEEE, dd MMM').format(r.date),
                style: context.typography.bodyMediumSemiBold),
          ),
          Text(r.status, style: context.typography.bodySmallSemiBold.copyWith(color: color)),
        ],
      ),
    );
  }
}
