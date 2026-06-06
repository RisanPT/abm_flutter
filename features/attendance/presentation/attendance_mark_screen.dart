import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/attendance/domain/attendance_model.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_controller.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AttendanceMarkScreen extends ConsumerStatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  ConsumerState<AttendanceMarkScreen> createState() =>
      _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends ConsumerState<AttendanceMarkScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassroom;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final classroomsAsync = ref.watch(attendanceClassroomsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: classroomsAsync.when(
        data: (classrooms) {
          if (classrooms.isEmpty) {
            return const Center(child: Text('No classes available for attendance.'));
          }

          _selectedClassroom ??= classrooms.first;
          final attendanceAsync = ref.watch(
            attendanceControllerProvider(
              date: _selectedDate,
              classroom: _selectedClassroom,
            ),
          );

          return Column(
            children: [
              _AttendanceHeader(
                selectedDate: _selectedDate,
                selectedClassroom: _selectedClassroom ?? classrooms.first,
                classrooms: classrooms,
                user: user,
                searchQuery: _searchQuery,
                onSelectClassroom: (value) {
                  setState(() => _selectedClassroom = value);
                },
                onSearchChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onMarkAllPresent: () {
                  ref
                      .read(
                        attendanceControllerProvider(
                          date: _selectedDate,
                          classroom: _selectedClassroom,
                        ).notifier,
                      )
                      .markAll(AttendanceStatus.present);
                },
                onSelectDate: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              Expanded(
                child: attendanceAsync.when(
                  data: (records) {
                    final filteredRecords = records.where((record) {
                      final query = _searchQuery.trim().toLowerCase();
                      if (query.isEmpty) {
                        return true;
                      }
                      final name = (record.studentName ?? '').toLowerCase();
                      final id = record.studentId.toLowerCase();
                      return name.contains(query) || id.contains(query);
                    }).toList();

                    final presentCount = filteredRecords
                        .where((record) => record.status == AttendanceStatus.present)
                        .length;
                    final lateCount = filteredRecords
                        .where((record) => record.status == AttendanceStatus.late)
                        .length;
                    final absentCount = filteredRecords
                        .where((record) => record.status == AttendanceStatus.absent)
                        .length;

                    return Column(
                      children: [
                        Expanded(
                          child: filteredRecords.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 36,
                                        color: colors.textSecondary,
                                      ),
                                      const Gap(10),
                                      Text(
                                        _searchQuery.trim().isEmpty
                                            ? 'No students found for this class'
                                            : 'No students match your search',
                                        style: context.typography.bodyMedium.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    context.isMobile ? 14 : 20,
                                    12,
                                    context.isMobile ? 14 : 20,
                                    16,
                                  ),
                                  itemCount: filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    final record = filteredRecords[index];
                                    return _AttendanceRow(
                                      record: record,
                                      classroom: _selectedClassroom,
                                      date: _selectedDate,
                                    );
                                  },
                                ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            context.isMobile ? 14 : 20,
                            12,
                            context.isMobile ? 14 : 20,
                            context.isMobile ? 14 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: colors.white,
                            border: Border(top: BorderSide(color: colors.border)),
                          ),
                          child: context.isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '$presentCount Present',
                                          style: context.typography.bodyMediumSemiBold.copyWith(
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const Gap(14),
                                        if (lateCount > 0)
                                          Text(
                                            '$lateCount Late',
                                            style: context.typography.bodyMediumSemiBold.copyWith(
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        if (lateCount > 0) const Gap(14),
                                        Text(
                                          '$absentCount Absent',
                                          style: context.typography.bodyMediumSemiBold.copyWith(
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(12),
                                    ABMButton(
                                      text: 'Save Records',
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              attendanceControllerProvider(
                                                date: _selectedDate,
                                                classroom: _selectedClassroom,
                                              ).notifier,
                                            )
                                            .saveAttendance(user?.username ?? 'Admin');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Attendance saved successfully'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Text(
                                      '$presentCount Present',
                                      style: context.typography.bodyMediumSemiBold.copyWith(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const Gap(18),
                                    if (lateCount > 0)
                                      Text(
                                        '$lateCount Late',
                                        style: context.typography.bodyMediumSemiBold.copyWith(
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    if (lateCount > 0) const Gap(18),
                                    Text(
                                      '$absentCount Absent',
                                      style: context.typography.bodyMediumSemiBold.copyWith(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: 190,
                                      child: ABMButton(
                                        text: 'Save Records',
                                        onPressed: () async {
                                          await ref
                                              .read(
                                                attendanceControllerProvider(
                                                  date: _selectedDate,
                                                  classroom: _selectedClassroom,
                                                ).notifier,
                                              )
                                              .saveAttendance(user?.username ?? 'Admin');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Attendance saved successfully'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({
    required this.selectedDate,
    required this.selectedClassroom,
    required this.classrooms,
    required this.user,
    required this.searchQuery,
    required this.onSelectClassroom,
    required this.onSearchChanged,
    required this.onMarkAllPresent,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final String selectedClassroom;
  final List<String> classrooms;
  final UserModel? user;
  final String searchQuery;
  final ValueChanged<String> onSelectClassroom;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMobile = context.isMobile;
    final filterCardPadding = isMobile ? 10.0 : 16.0;
    final sectionGap = isMobile ? 10.0 : 18.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F4A3A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AbmPatternPainter(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 20,
              MediaQuery.of(context).padding.top + (isMobile ? 6 : 12),
              isMobile ? 14 : 20,
              isMobile ? 10 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6B64C),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'Attendance',
                      style: typography.h3.copyWith(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 24,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push(RouteNames.attendanceReport),
                      icon: const Icon(LucideIcons.barChart2, color: Colors.white70),
                      tooltip: 'View Monthly Reports',
                    ),
                    if (user != null)
                      Text(
                        user!.role.label,
                        style: typography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
                Gap(sectionGap),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: typography.bodyMedium.copyWith(
                      color: const Color(0xFF163D32),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search student...',
                      hintStyle: typography.bodyMedium.copyWith(
                        color: const Color(0xFF8B928F),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF7D857F),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 10 : 14,
                      ),
                    ),
                  ),
                ),
                Gap(sectionGap),
                Container(
                  padding: EdgeInsets.all(filterCardPadding),
                  decoration: BoxDecoration(
                    color: colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _HeaderTile(
                        title: 'CLASS / SECTION',
                        child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedClassroom,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          iconEnabledColor: const Color(0xFF7A837E),
                          style: typography.bodyMediumSemiBold.copyWith(
                            color: const Color(0xFF163D32),
                          ),
                          items: classrooms
                              .map(
                                  (classroom) => DropdownMenuItem(
                                    value: classroom,
                                    child: Text(
                                      classroom,
                                      style: typography.bodyMediumSemiBold.copyWith(
                                        color: const Color(0xFF163D32),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                onSelectClassroom(value);
                              }
                            },
                          ),
                        ),
                      ),
                      Gap(isMobile ? 8 : 14),
                      _HeaderTile(
                        title: user?.role == AppRoles.teacher
                            ? 'DATE'
                            : 'DATE (HEAD MASTER)',
                        child: InkWell(
                          onTap: onSelectDate,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('EEE, dd MMM yyyy').format(selectedDate),
                                  style: typography.bodyMediumSemiBold.copyWith(
                                    color: const Color(0xFF163D32),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Color(0xFF7A837E),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(sectionGap),
                Row(
                  children: [
                    Text(
                      'Students List',
                      style: typography.bodyLargeSemiBold.copyWith(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 22,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onMarkAllPresent,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 14,
                          vertical: isMobile ? 7 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6B64C).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFD6B64C).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.done_all,
                              size: 16,
                              color: Color(0xFFD6B64C),
                            ),
                            if (!isMobile) ...[
                              const Gap(8),
                              Text(
                                'Mark All Present',
                                style: typography.bodyMediumSemiBold.copyWith(
                                  color: const Color(0xFFD6B64C),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTile extends StatelessWidget {
  const _HeaderTile({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 12 : 14,
        vertical: context.isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(context.isMobile ? 14 : 16),
        border: Border.all(color: const Color(0xFFE7E3D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typography.caption.copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A8A81),
            ),
          ),
          Gap(context.isMobile ? 4 : 8),
          DefaultTextStyle(
            style: typography.bodyMediumSemiBold.copyWith(
              color: const Color(0xFF163D32),
              fontSize: context.isMobile ? 14 : null,
            ),
            child: IconTheme(
              data: const IconThemeData(color: Color(0xFF7A837E)),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends ConsumerWidget {
  const _AttendanceRow({
    required this.record,
    required this.classroom,
    required this.date,
  });

  final AttendanceModel record;
  final String? classroom;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    const rowTitleColor = Color(0xFF163D32);
    const rowSubtleColor = Color(0xFF6F7A75);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(context.isMobile ? 9 : 12),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.isMobile ? 22 : 24,
            backgroundColor: const Color(0xFFE8EFEA),
            child: Text(
              (record.studentName ?? 'S')[0].toUpperCase(),
              style: context.typography.bodyMediumSemiBold.copyWith(
                color: colors.primary,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName ?? 'Student',
                  style: context.typography.bodyMediumSemiBold.copyWith(
                    color: rowTitleColor,
                    fontSize: context.isMobile ? 14 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(3),
                Text(
                  'ID: ${record.studentId}',
                  style: context.typography.bodySmall.copyWith(
                    color: rowSubtleColor,
                    fontSize: context.isMobile ? 12 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _StatusSwitch(
            status: record.status,
            onChanged: (status) {
              ref
                  .read(
                    attendanceControllerProvider(
                      date: date,
                      classroom: classroom,
                    ).notifier,
                  )
                  .updateStatus(record.studentId, status);
            },
          ),
        ],
      ),
    );
  }
}

class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({required this.status, required this.onChanged});

  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFD6B64C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchChip(
            color: Colors.green,
            selected: status == AttendanceStatus.present,
            onTap: () => onChanged(AttendanceStatus.present),
          ),
          const Gap(6),
          _SwitchChip(
            color: Colors.orange,
            selected: status == AttendanceStatus.late,
            onTap: () => onChanged(AttendanceStatus.late),
          ),
          const Gap(6),
          _SwitchChip(
            color: Colors.red,
            selected: status == AttendanceStatus.absent,
            onTap: () => onChanged(AttendanceStatus.absent),
          ),
        ],
      ),
    );
  }
}

class _SwitchChip extends StatelessWidget {
  const _SwitchChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 38,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
