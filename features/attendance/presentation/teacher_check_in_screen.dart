import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_report_screen.dart';
import 'package:abm_madrasa/features/attendance/presentation/secure_attendance_screen.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Teacher self check-in screen.
/// Accessible by the Teacher role — lets them record their own daily attendance.
class TeacherCheckInScreen extends ConsumerStatefulWidget {
  const TeacherCheckInScreen({super.key});

  @override
  ConsumerState<TeacherCheckInScreen> createState() => _TeacherCheckInScreenState();
}

class _TeacherCheckInScreenState extends ConsumerState<TeacherCheckInScreen> {
  bool _checkedInToday = false;
  String _selectedStatus = 'Present';

  final _statuses = ['Present', 'Late', 'Absent'];

  @override
  void initState() {
    super.initState();
    _checkTodayStatus();
  }

  Future<void> _checkTodayStatus() async {
    try {
      final dio = ref.read(dioProvider);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await dio.get('/attendance', queryParameters: {
        'date': today,
        'type': 'Teacher',
      });
      final records = response.data as List? ?? [];
      final user = ref.read(authControllerProvider).value;
      final alreadyCheckedIn = records.any((r) {
        final tid = r['teacherId'];
        if (tid is Map) return tid['_id']?.toString() == user?.id;
        return tid?.toString() == user?.id;
      });
      if (mounted) setState(() { _checkedInToday = alreadyCheckedIn; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final user = ref.watch(authControllerProvider).value;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('My Attendance', style: typography.h3),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
            ),
            icon: const Icon(LucideIcons.barChart2),
            tooltip: 'View Reports',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primary.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(today),
                    style: typography.h2.copyWith(color: Colors.white),
                  ),
                  const Gap(4),
                  Text(
                    DateFormat('dd MMMM yyyy').format(today),
                    style: typography.bodyLarge.copyWith(color: Colors.white70),
                  ),
                  const Gap(16),
                  if (user != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null
                              ? Text(user.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        const Gap(12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.username,
                                style: typography.bodyMediumSemiBold.copyWith(color: Colors.white)),
                            Text(user.role.label,
                                style: typography.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const Gap(28),

            // Status selector
            Text('Mark Your Attendance', style: typography.h4),
            const Gap(16),
            Row(
              children: _statuses
                  .map((s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _StatusCard(
                            label: s,
                            isSelected: _selectedStatus == s,
                            color: s == 'Present'
                                ? Colors.green
                                : s == 'Late'
                                    ? Colors.orange
                                    : Colors.red,
                            onTap: () => setState(() => _selectedStatus = s),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const Gap(24),

            // Check-in button
            if (_checkedInToday)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Colors.green),
                    const Gap(12),
                    Text(
                      'Attendance recorded for today',
                      style: typography.bodyLargeSemiBold.copyWith(color: Colors.green.shade700),
                    ),
                  ],
                ),
              )
            else
              ABMButton(
                text: 'Record Attendance',
                onPressed: _checkIn,
              ),

            const Gap(32),

            // How-to note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, color: colors.textSecondary, size: 18),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'You can only submit attendance once per day. '
                      'If you need to correct it, contact the Head Master.',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkIn() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SecureAttendanceScreen()),
    );
    if (result == true && mounted) {
      setState(() {
        _checkedInToday = true;
      });
    }
  }
}

// ── Status Card Widget ────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
