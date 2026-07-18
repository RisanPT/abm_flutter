import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/institute_time.dart';
import 'package:abm_madrasa/features/attendance/domain/attendance_model.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_controller.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
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
  DateTime _selectedDate = instituteToday();
  String? _selectedClassroom;
  final String _academicYear = '2026-2027';
  String _searchQuery = '';
  String _selectedType = 'Student';
  String _selectedShift = 'Shift-1';

  /// Chooses an accurate empty-state icon + message: distinguishes "no class
  /// scheduled on this date" from "class is scheduled but nobody is enrolled".
  ({IconData icon, String message}) _emptyState(List<String> scheduled, String? classroom) {
    if (_searchQuery.trim().isNotEmpty) {
      return (icon: LucideIcons.search, message: 'No results match your search.');
    }
    if (_selectedType == 'Teacher') {
      return (icon: LucideIcons.calendarOff, message: 'No classes scheduled for this date.');
    }
    final cls = classroom ?? '';
    if (cls.isNotEmpty && scheduled.contains(cls)) {
      return (
        icon: LucideIcons.userX,
        message: 'No $_selectedShift students enrolled in $cls.\nAdd students to this class to mark attendance.',
      );
    }
    return (
      icon: LucideIcons.calendarOff,
      message: 'No class scheduled${cls.isEmpty ? '' : ' for $cls'} on this date.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final allowedModules = user != null ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role) : <String>{};
    final canManageTeachers = user?.role.canAccess(AppModule.teachers, allowedModules) ?? false;
    final classroomsAsync = ref.watch(attendanceClassroomsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: classroomsAsync.when(
        data: (classrooms) {
          if (classrooms.isNotEmpty) {
            _selectedClassroom ??= classrooms.first;
          }

          if (classrooms.isEmpty && _selectedType == 'Student') {
            return Column(
              children: [
                _AttendanceHeader(
                  selectedDate: _selectedDate,
                  selectedClassroom: null,
                  classrooms: const [],
                  user: user,
                  allowedModules: allowedModules,
                  searchQuery: _searchQuery,
                  selectedType: _selectedType,
                  selectedShift: _selectedShift,
                  onTypeChanged: (val) => setState(() => _selectedType = val),
                  onShiftChanged: (val) => setState(() => _selectedShift = val),
                  onSelectClassroom: (value) {},
                  onSearchChanged: (value) => setState(() => _searchQuery = value),
                  onMarkAllPresent: () {},
                  onSelectDate: () {},
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.school, size: 48, color: colors.textSecondary),
                        const Gap(16),
                        Text(
                          'No classrooms found',
                          style: context.typography.h3.copyWith(color: colors.textSecondary),
                        ),
                        const Gap(8),
                        Text(
                          'Add classrooms to this institute to start marking attendance.',
                          style: context.typography.bodyMedium.copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(24),
                        if (canManageTeachers)
                          ABMButton(
                            text: 'Manage Classrooms',
                            icon: LucideIcons.layers,
                            onPressed: () => context.go(RouteNames.classrooms),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final year = _selectedDate.year;
          final month = _selectedDate.month;
          final academicYear = _academicYear;
          final instituteId = ref.watch(selectedInstituteProvider).id;

          // Classrooms that have a timetable entry on the selected date
          final scheduledClassroomsAsync = ref.watch(
            scheduledClassroomsForDateProvider((
              date: _selectedDate,
              shift: _selectedShift,
              academicYear: academicYear,
              year: year,
              month: month,
              instituteId: instituteId,
            )),
          );
          final scheduledClassrooms = scheduledClassroomsAsync.asData?.value ?? classrooms;

          if (scheduledClassrooms.isNotEmpty && (_selectedClassroom == null || !scheduledClassrooms.contains(_selectedClassroom))) {
            _selectedClassroom = scheduledClassrooms.first;
          }

          final effectiveClassroom = _selectedType == 'Teacher' ? null : (_selectedClassroom ?? (scheduledClassrooms.isNotEmpty ? scheduledClassrooms.first : null));

          final attendanceAsync = ref.watch(
            attendanceControllerProvider(
              date: _selectedDate,
              classroom: effectiveClassroom,
              type: _selectedType,
              shift: _selectedShift,
              academicYear: _academicYear,
            ),
          );

          return Column(
            children: [
              _AttendanceHeader(
                selectedDate: _selectedDate,
                selectedClassroom: effectiveClassroom ?? '',
                classrooms: scheduledClassrooms,
                user: user,
                allowedModules: allowedModules,
                searchQuery: _searchQuery,
                selectedType: _selectedType,
                selectedShift: _selectedShift,
                onTypeChanged: (val) => setState(() => _selectedType = val),
                onShiftChanged: (val) => setState(() {
                  _selectedShift = val;
                  _selectedDate = instituteToday();
                }),
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
                          classroom: _selectedType == 'Teacher' ? null : effectiveClassroom,
                          type: _selectedType,
                          shift: _selectedShift,
                          academicYear: _academicYear,
                        ).notifier,
                      )
                      .markAll(AttendanceStatus.present);
                },
                onSelectDate: () async {
                  final today = instituteToday();
                  // Free calendar: pick any day up to today. Days without a
                  // scheduled class just show the "No class scheduled" state,
                  // so the admin can navigate freely instead of being locked
                  // to a handful of class dates.
                  final initial = _selectedDate.isAfter(today) ? today : _selectedDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.utc(2020, 1, 1),
                    lastDate: today,
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = DateTime.utc(picked.year, picked.month, picked.day));
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
                      final name = (record.studentName ?? record.teacherName ?? '').toLowerCase();
                      final id = (record.studentId ?? record.teacherId ?? '').toLowerCase();
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

                    final empty = _emptyState(scheduledClassrooms, effectiveClassroom);

                    return Column(
                      children: [
                        Expanded(
                          child: filteredRecords.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        empty.icon,
                                        size: 48,
                                        color: colors.textSecondary.withValues(alpha: 0.5),
                                      ),
                                      const Gap(16),
                                      Text(
                                        empty.message,
                                        style: context.typography.bodyMedium.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
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
                                      shift: _selectedShift,
                                      academicYear: _academicYear,
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
                                                classroom: _selectedType == 'Teacher' ? null : _selectedClassroom,
                                                type: _selectedType,
                                                shift: _selectedShift,
                                                academicYear: _academicYear,
                                              ).notifier,
                                            )
                                            .saveAttendance(user?.username ?? 'Admin', classroomName: _selectedType == 'Student' ? effectiveClassroom : null);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _selectedType == 'Teacher'
                                                    ? 'Teacher attendance saved successfully'
                                                    : 'Student attendance saved successfully',
                                              ),
                                              backgroundColor: Colors.green.shade700,
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
                                                  classroom: _selectedType == 'Teacher' ? null : _selectedClassroom,
                                                  type: _selectedType,
                                                  shift: _selectedShift,
                                                  academicYear: _academicYear,
                                                ).notifier,
                                              )
                                              .saveAttendance(user?.username ?? 'Admin', classroomName: _selectedType == 'Student' ? effectiveClassroom : null);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _selectedType == 'Teacher'
                                                      ? 'Teacher attendance saved successfully'
                                                      : 'Student attendance saved successfully',
                                                ),
                                                backgroundColor: Colors.green.shade700,
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
    required this.allowedModules,
    required this.searchQuery,
    required this.selectedType,
    required this.selectedShift,
    required this.onTypeChanged,
    required this.onShiftChanged,
    required this.onSelectClassroom,
    required this.onSearchChanged,
    required this.onMarkAllPresent,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final String? selectedClassroom;
  final List<String> classrooms;
  final UserModel? user;
  final Set<String> allowedModules;
  final String searchQuery;
  final String selectedType;
  final String selectedShift;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onShiftChanged;
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
    final canManageTeachers = user?.role.canAccess(AppModule.teachers, allowedModules) ?? false;

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
                      onPressed: () => context.push(RouteNames.studentAttendanceReport),
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
                      hintText: selectedType == 'Teacher' ? 'Search teacher...' : 'Search student...',
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
                      if (canManageTeachers)
                        Row(
                          children: [
                            Expanded(
                              child: _TypeToggleTab(
                                title: 'Students',
                                isSelected: selectedType == 'Student',
                                onTap: () => onTypeChanged('Student'),
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: _TypeToggleTab(
                                title: 'Teachers',
                                isSelected: selectedType == 'Teacher',
                                onTap: () => onTypeChanged('Teacher'),
                              ),
                            ),
                          ],
                        ),
                      if (canManageTeachers)
                        Gap(isMobile ? 12 : 18),
                      if (selectedType == 'Student') ...[
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
                      ],
                      _HeaderTile(
                        title: 'SHIFT',
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedShift,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            iconEnabledColor: const Color(0xFF7A837E),
                            style: typography.bodyMediumSemiBold.copyWith(
                              color: const Color(0xFF163D32),
                            ),
                            items: ['Shift-1', 'Shift-2']
                                .map(
                                  (shift) => DropdownMenuItem(
                                    value: shift,
                                    child: Text(
                                      shift,
                                      style: typography.bodyMediumSemiBold.copyWith(
                                        color: const Color(0xFF163D32),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                onShiftChanged(value);
                              }
                            },
                          ),
                        ),
                      ),
                      Gap(isMobile ? 8 : 14),
                      _HeaderTile(
                        title: 'DATE',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onSelectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6B64C).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD6B64C).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 16,
                                    color: const Color(0xFF163D32),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEE, dd MMM yyyy').format(selectedDate),
                                      style: typography.bodyMediumSemiBold.copyWith(
                                        color: const Color(0xFF163D32),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    LucideIcons.chevronDown,
                                    size: 16,
                                    color: Color(0xFF163D32),
                                  ),
                                ],
                              ),
                            ),
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
                      selectedType == 'Teacher' ? 'Teachers Attendance' : 'Students Attendance',
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
    required this.shift,
    required this.academicYear,
  });

  final AttendanceModel record;
  final String? classroom;
  final DateTime date;
  final String shift;
  final String academicYear;

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
              ((record.teacherId != null && record.teacherId!.isNotEmpty)
                  ? record.teacherName
                  : record.studentName)?.isNotEmpty == true
                  ? ((record.teacherId != null && record.teacherId!.isNotEmpty)
                      ? record.teacherName!
                      : record.studentName!)[0].toUpperCase()
                  : '?',
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
                  (record.teacherId != null && record.teacherId!.isNotEmpty)
                      ? (record.teacherName ?? 'Unknown Teacher')
                      : (record.studentName ?? 'Unknown Student'),
                  style: context.typography.bodyMediumSemiBold.copyWith(
                    color: rowTitleColor,
                    fontSize: context.isMobile ? 14 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(3),
                Text(
                  (record.teacherId != null && record.teacherId!.isNotEmpty)
                      ? 'Teacher ID: ${record.teacherId ?? 'N/A'}'
                      : 'Adm: ${record.admissionNumber?.isNotEmpty == true ? record.admissionNumber : record.studentId ?? 'N/A'}',
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
              final isTeacher = record.teacherId != null && record.teacherId!.isNotEmpty;
              final targetId = isTeacher ? record.teacherId! : record.studentId!;
              
              ref
                  .read(
                    attendanceControllerProvider(
                      date: date,
                      classroom: isTeacher ? null : classroom,
                      type: isTeacher ? 'Teacher' : 'Student',
                      shift: shift,
                      academicYear: academicYear,
                    ).notifier,
                  )
                  .updateStatus(targetId, status, type: isTeacher ? 'Teacher' : 'Student');
            },
          ),
        ],
      ),
    );
  }
}

class _TypeToggleTab extends StatelessWidget {
  const _TypeToggleTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD6B64C) : const Color(0xFFF8F7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD6B64C) : const Color(0xFFE7E3D7),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: typography.bodyMediumSemiBold.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF8A8A81),
          ),
        ),
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
