import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final asyncStudent = ref.watch(studentDetailsProvider(studentId));

    return asyncStudent.when(
      data: (student) => _StudentProfileBody(student: student),
      loading: () => initialStudent != null
          ? _StudentProfileBody(student: initialStudent!)
          : Scaffold(
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
                  tooltip: student.isActive ? 'Deactivate' : 'Reactivate',
                  icon: Icon(student.isActive ? LucideIcons.userX : LucideIcons.userCheck, color: Colors.white),
                  onPressed: () => _confirmToggleActive(context, ref),
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
      ABMButton(text: 'Download ID Card', onPressed: () => _downloadIdCard(context), isSecondary: true),
      ABMButton(text: 'Message Parent', onPressed: () => _messageParent(context)),
    ];

    return context.isMobile
        ? Column(children: [btns[0], const Gap(12), btns[1]])
        : Row(children: [Expanded(child: btns[0]), const Gap(12), Expanded(child: btns[1])]);
  }

  // Open WhatsApp to the parent's number on file.
  Future<void> _messageParent(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final digits = student.guardianContact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No parent contact is on file for this student.')));
      return;
    }
    final uri = Uri.parse('https://wa.me/$digits');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  // Generate and share/print a simple student ID card.
  Future<void> _downloadIdCard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6.landscape,
          build: (_) => pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFF1B3D2F), width: 2),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Anas Bin Malik Madrasa',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1B3D2F))),
                pw.Text('Student Identity Card', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Divider(color: PdfColor.fromInt(0xFFB8860B)),
                pw.SizedBox(height: 6),
                _idRow('Name', student.fullName),
                _idRow('Student ID', student.admissionNumber),
                _idRow('Class', student.classroom),
                _idRow('Guardian Contact', student.guardianContact),
              ],
            ),
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  static pw.Widget _idRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
        ]),
      );

  Future<void> _confirmToggleActive(BuildContext context, WidgetRef ref) async {
    final deactivating = student.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deactivating ? 'Deactivate Student' : 'Reactivate Student'),
        content: Text(deactivating
            ? '${student.fullName} will be marked inactive and hidden from active lists, counts and attendance. You can reactivate anytime.'
            : 'Reactivate ${student.fullName} and include them in active lists again?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: deactivating ? Colors.orange.shade700 : Colors.green),
            child: Text(deactivating ? 'Deactivate' : 'Reactivate', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(studentControllerProvider.notifier).setActive(student.id, !student.isActive);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(deactivating ? 'Student deactivated' : 'Student reactivated')),
          );
          context.go(RouteNames.students);
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
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
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
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
              Text(friendlyErrorMessage(message), textAlign: TextAlign.center, style: context.typography.bodyMedium.copyWith(color: const Color(0xFF6F7A75))),
            ],
          ),
        ),
      ),
    );
  }
}
