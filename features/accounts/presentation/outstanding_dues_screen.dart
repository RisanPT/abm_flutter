import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/institute_banner_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

class _DueStudent {
  final String studentId;
  final String fullName;
  final String classroom;
  final String guardianName;
  final String guardianContact;
  final String? photoUrl;
  final String monthLabel;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final String status;

  const _DueStudent({
    required this.studentId,
    required this.fullName,
    required this.classroom,
    required this.guardianName,
    required this.guardianContact,
    required this.photoUrl,
    required this.monthLabel,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.status,
  });

  factory _DueStudent.fromJson(Map<String, dynamic> j) => _DueStudent(
        studentId: (j['studentId'] as String?) ?? (j['_id'] as String?) ?? '',
        fullName: j['fullName'] as String? ?? '',
        classroom: j['classroom'] as String? ?? '',
        guardianName: j['guardianName'] as String? ?? '',
        guardianContact: j['guardianContact'] as String? ?? '',
        photoUrl: j['photoUrl'] as String?,
        monthLabel: j['monthLabel'] as String? ?? '',
        totalDue: (j['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (j['totalPaid'] as num?)?.toDouble() ?? 0,
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'Pending',
      );
}

class _DuesSummary {
  final double totalOutstanding;
  final double totalCollected;
  final int studentsWithDues;
  final int totalStudents;
  final List<_DueStudent> students;

  const _DuesSummary({
    required this.totalOutstanding,
    required this.totalCollected,
    required this.studentsWithDues,
    required this.totalStudents,
    required this.students,
  });
}

// ─── Provider ──────────────────────────────────────────────────────────────────

final _outstandingDuesProvider = FutureProvider.autoDispose.family<_DuesSummary, String>((ref, instituteId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/accounts/outstanding-dues', queryParameters: {
    if (instituteId.isNotEmpty) 'instituteId': instituteId,
  });
  final data = response.data as Map<String, dynamic>;
  final summary = data['summary'] as Map<String, dynamic>;
  final rawStudents = (data['students'] as List?) ?? [];
  return _DuesSummary(
    totalOutstanding: (summary['totalOutstanding'] as num?)?.toDouble() ?? 0,
    totalCollected: (summary['totalCollected'] as num?)?.toDouble() ?? 0,
    studentsWithDues: (summary['studentsWithDues'] as int?) ?? 0,
    totalStudents: (summary['totalStudents'] as int?) ?? 0,
    students: rawStudents.map((e) => _DueStudent.fromJson(e as Map<String, dynamic>)).toList(),
  );
});

// ─── Screen ─────────────────────────────────────────────────────────────────────

class OutstandingDuesScreen extends ConsumerStatefulWidget {
  const OutstandingDuesScreen({super.key});

  @override
  ConsumerState<OutstandingDuesScreen> createState() => _OutstandingDuesScreenState();
}

class _OutstandingDuesScreenState extends ConsumerState<OutstandingDuesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final institute = ref.watch(selectedInstituteProvider);
    final asyncData = ref.watch(_outstandingDuesProvider(institute.id));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Outstanding Dues', style: typography.h3),
        actions: [
          const InstituteBannerChip(),
          asyncData.whenData((data) => IconButton(
            onPressed: () => _exportPdf(data),
            icon: const Icon(LucideIcons.download),
            tooltip: 'Export PDF',
          )).value ?? const SizedBox.shrink(),
          const Gap(8),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => _buildBody(context, data),
      ),
    );
  }

  Widget _buildBody(BuildContext context, _DuesSummary data) {
    final colors = context.colors;
    final typography = context.typography;

    final filtered = data.students.where((s) {
      if (_search.isEmpty) return true;
      return s.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          s.classroom.toLowerCase().contains(_search.toLowerCase()) ||
          s.guardianName.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final cards = [
              _SummaryCard(
                title: 'Total Outstanding',
                value: 'SAR ${data.totalOutstanding.toStringAsFixed(0)}',
                icon: LucideIcons.alertCircle,
                color: Colors.red,
                gradient: true,
              ),
              _SummaryCard(
                title: 'Students with Dues',
                value: '${data.studentsWithDues}',
                icon: LucideIcons.users,
                color: Colors.orange,
              ),
              _SummaryCard(
                title: 'Total Collected',
                value: 'SAR ${data.totalCollected.toStringAsFixed(0)}',
                icon: LucideIcons.checkCircle,
                color: Colors.green,
              ),
            ];
            return isWide
                ? Row(children: cards.expand((c) => [Expanded(child: c), const Gap(16)]).toList()..removeLast())
                : Column(children: cards.expand((c) => [c, const Gap(12)]).toList()..removeLast());
          }),
          const Gap(24),

          // Search bar
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search by name, class or guardian...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              filled: true,
              fillColor: colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const Gap(16),

          Row(
            children: [
              Text('${filtered.length} Students with Outstanding Fees', style: typography.h4),
            ],
          ),
          const Gap(12),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCircle2, size: 48, color: Colors.green.shade400),
                        const Gap(12),
                        Text(
                          _search.isEmpty ? 'All fees are cleared! 🎉' : 'No matching students found',
                          style: typography.bodyLargeSemiBold.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _DueCard(
                      student: filtered[index],
                      onTap: () => context.push('${RouteNames.accounts}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(_DuesSummary data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Outstanding Dues Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Total Outstanding: SAR ${data.totalOutstanding.toStringAsFixed(2)}'),
          pw.Text('Students with Dues: ${data.studentsWithDues}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Class', 'Guardian', 'Due', 'Paid', 'Balance', 'Status'],
            data: data.students.map((s) => [
              s.fullName,
              s.classroom,
              s.guardianName,
              'SAR ${s.totalDue.toStringAsFixed(0)}',
              'SAR ${s.totalPaid.toStringAsFixed(0)}',
              'SAR ${s.balance.toStringAsFixed(0)}',
              s.status,
            ]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color, this.gradient = false});
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient ? null : context.colors.white,
        gradient: gradient
            ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        borderRadius: BorderRadius.circular(20),
        border: gradient ? null : Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gradient ? Colors.white : color, size: 24),
          const Gap(12),
          Text(value,
              style: context.typography.h3.copyWith(
                color: gradient ? Colors.white : context.colors.textPrimary,
                fontSize: 22,
              )),
          const Gap(4),
          Text(title,
              style: context.typography.bodySmall.copyWith(
                color: gradient ? Colors.white70 : context.colors.textSecondary,
              )),
        ],
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.student, required this.onTap});
  final _DueStudent student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isPending = student.status == 'Pending';
    final statusColor = isPending ? Colors.red : Colors.orange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: statusColor.withValues(alpha: 0.1),
              backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: student.photoUrl == null || student.photoUrl!.isEmpty
                  ? Text(
                      student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                      style: TextStyle(fontWeight: FontWeight.w800, color: statusColor),
                    )
                  : null,
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName, style: typography.bodyLargeSemiBold),
                  Text('${student.classroom} • ${student.monthLabel}',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                  Text('Guardian: ${student.guardianName}',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('SAR ${student.balance.toStringAsFixed(0)}',
                    style: typography.bodyLargeSemiBold.copyWith(color: statusColor)),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(student.status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
