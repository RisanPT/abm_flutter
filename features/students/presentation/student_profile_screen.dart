import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_controller.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/student_controller.dart';
import 'package:abm_madrasa/features/students/presentation/widgets/student_profile_widgets.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudentProfileScreen extends ConsumerWidget {
  final String studentId;
  final StudentModel? initialStudent;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    this.initialStudent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudent = initialStudent != null
        ? AsyncValue.data(initialStudent!)
        : ref.watch(studentDetailsProvider(studentId));

    return asyncStudent.when(
      data: (student) => _StudentProfileBody(student: student),
      loading: () => Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorState(message: error.toString()),
    );
  }
}

class _StudentProfileBody extends ConsumerWidget {
  const _StudentProfileBody({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ABMPageHeader(
              title: student.fullName,
              subtitle: 'Class: ${student.classroom}',
              height: context.isMobile ? 320 : 360,
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.edit3, color: Colors.white),
                  onPressed: () => context.push('${RouteNames.editStudent}/${student.id}', extra: student),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.white),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
              bottomChild: Center(
                child: Hero(
                  tag: 'student_photo_${student.id}',
                  child: CircleAvatar(
                    radius: context.isMobile ? 42 : 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    backgroundImage: student.photoUrl?.isNotEmpty == true ? NetworkImage(student.photoUrl!) : null,
                    child: student.photoUrl?.isNotEmpty != true
                        ? Text(
                            (student.fullName.isEmpty ? 'S' : student.fullName[0]).toUpperCase(),
                            style: context.typography.h1.copyWith(color: Colors.white, fontSize: context.isMobile ? 32 : 40),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.isMobile ? 16 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildQuickStats(context, ref),
                      const Gap(24),
                      _buildInfoSections(context),
                      const Gap(32),
                      _buildActions(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final feeAsync = ref.watch(studentAccountDetailsProvider(student.id));
    final feeStatus = feeAsync.maybeWhen(
      data: (details) => details.status,
      orElse: () => '...',
    );
    final feeColor = feeAsync.maybeWhen(
      data: (details) {
        switch (details.status) {
          case 'Paid': return Colors.green;
          case 'Partially Paid': return Colors.orange;
          default: return Colors.red;
        }
      },
      orElse: () => Colors.grey,
    );

    final widgets = [
      StatCard(label: 'Attendance', value: '${(student.attendancePercentage ?? 0).toInt()}%', icon: LucideIcons.calendarCheck2, color: Colors.blue),
      StatCard(label: 'Fee Status', value: feeStatus, icon: LucideIcons.wallet, color: feeColor),
    ];

    return context.isMobile
        ? Column(children: [widgets[0], const Gap(12), widgets[1]])
        : Row(children: [Expanded(child: widgets[0]), const Gap(16), Expanded(child: widgets[1])]);
  }

  Widget _buildInfoSections(BuildContext context) {
    return Column(
      children: [
        InfoSection(
          title: 'Personal Information',
          icon: LucideIcons.user,
          children: [
            InfoRow(label: 'Admission No.', value: student.admissionNumber),
            InfoRow(label: 'Date of Birth', value: DateFormat('dd MMM yyyy').format(student.dateOfBirth)),
            InfoRow(label: 'Gender', value: student.gender.name.toUpperCase()),
            InfoRow(label: 'Blood Group', value: student.bloodGroup ?? 'N/A'),
          ],
        ),
        const Gap(24),
        InfoSection(
          title: 'Guardian & Contact',
          icon: LucideIcons.users,
          children: [
            InfoRow(label: 'Guardian Name', value: student.guardianName),
            InfoRow(label: 'Contact No.', value: student.guardianContact),
            InfoRow(label: 'Address', value: student.address),
          ],
        ),
        const Gap(24),
        InfoSection(
          title: 'Parent Identification',
          icon: LucideIcons.fileText,
          children: [
            InfoRow(label: 'Passport ID', value: student.parentPassportId?.isNotEmpty == true ? student.parentPassportId! : 'Not Provided'),
            InfoRow(label: 'Iqama ID', value: student.parentIqamaId?.isNotEmpty == true ? student.parentIqamaId! : 'Not Provided'),
          ],
        ),
        const Gap(24),
        InfoSection(
          title: 'Transportation',
          icon: LucideIcons.bus,
          children: [
            InfoRow(
              label: 'Status',
              value: student.needsTransportation ? 'Opted In' : 'Opted Out',
              valueColor: student.needsTransportation ? Colors.green : Colors.grey,
            ),
            if (student.needsTransportation)
              InfoRow(label: 'Monthly Fee', value: 'SAR ${student.transportationFee.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final btns = [
      ABMButton(text: 'Download ID Card', onPressed: () {}, isSecondary: true),
      ABMButton(text: 'Message Parent', onPressed: () {}),
    ];

    return context.isMobile
        ? Column(children: [btns[0], const Gap(12), btns[1]])
        : Row(children: [Expanded(child: btns[0]), const Gap(12), Expanded(child: btns[1])]);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(studentControllerProvider.notifier).deleteStudent(student.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully')));
          context.go(RouteNames.students);
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 36, color: Colors.red.shade600),
              const Gap(12),
              Text('Unable to load student details', style: context.typography.bodyLargeSemiBold.copyWith(color: const Color(0xFF163D32))),
              const Gap(8),
              Text(message.replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: context.typography.bodyMedium.copyWith(color: const Color(0xFF6F7A75))),
            ],
          ),
        ),
      ),
    );
  }
}
