import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─── Model ─────────────────────────────────────────────────────────────────────

class _PortalData {
  final Map<String, dynamic> student;
  final List<dynamic> finance;
  final List<dynamic> reports;
  final List<dynamic> attendance;
  const _PortalData({
    required this.student,
    required this.finance,
    required this.reports,
    required this.attendance,
  });
}

// ─── Provider ──────────────────────────────────────────────────────────────────

final _portalProvider = FutureProvider.family<_PortalData, String>((ref, studentId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/students/public-portal/$studentId');
  final data = response.data as Map<String, dynamic>;
  return _PortalData(
    student: data['student'] as Map<String, dynamic>,
    finance: (data['finance'] as List?) ?? [],
    reports: (data['reports'] as List?) ?? [],
    attendance: (data['attendance'] as List?) ?? [],
  );
});

// ─── Screen ────────────────────────────────────────────────────────────────────

class ParentPortalScreen extends ConsumerStatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  ConsumerState<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends ConsumerState<ParentPortalScreen> {
  final _idController = TextEditingController();
  String? _searchedId;
  bool _hasSearched = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _search() {
    final id = _idController.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _searchedId = id;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.primary.withValues(alpha: 0.75)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 28),
                            ),
                            const Gap(16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Parent Portal', style: typography.h3.copyWith(color: Colors.white)),
                                Text('Anas Bin Malik Madrasa', style: typography.bodySmall.copyWith(color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Search card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Track Your Child\'s Progress', style: typography.h4),
                      const Gap(4),
                      Text(
                        'Enter the student ID provided at admission to view attendance, fees and reports.',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                      const Gap(20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _idController,
                              onSubmitted: (_) => _search(),
                              decoration: InputDecoration(
                                hintText: 'Enter Student ID (e.g. S1001)',
                                prefixIcon: const Icon(LucideIcons.search, size: 20),
                                filled: true,
                                fillColor: colors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const Gap(12),
                          ElevatedButton(
                            onPressed: _search,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                if (_hasSearched && _searchedId != null)
                  _PortalResults(studentId: _searchedId!),
                if (!_hasSearched)
                  _buildInfoCards(colors, typography),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(dynamic colors, dynamic typography) {
    return Column(
      children: [
        const Gap(8),
        Row(
          children: [
            Expanded(child: _InfoTile(icon: LucideIcons.calendarCheck2, label: 'Attendance', desc: 'Daily attendance records', color: Colors.blue)),
            const Gap(16),
            Expanded(child: _InfoTile(icon: LucideIcons.wallet, label: 'Fee Status', desc: 'Monthly payment history', color: Colors.green)),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(child: _InfoTile(icon: LucideIcons.fileBarChart, label: 'Progress', desc: 'Academic reports & grades', color: Colors.purple)),
            const Gap(16),
            Expanded(child: _InfoTile(icon: LucideIcons.user, label: 'Profile', desc: 'Student information', color: Colors.orange)),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  const _InfoTile({required this.icon, required this.label, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Gap(12),
          Text(label, style: context.typography.bodyLargeSemiBold),
          Text(desc, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Results Widget ─────────────────────────────────────────────────────────────

class _PortalResults extends ConsumerWidget {
  const _PortalResults({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final asyncData = ref.watch(_portalProvider(studentId));

    return asyncData.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.red),
            const Gap(12),
            Expanded(
              child: Text(
                e.toString().contains('404') ? 'Student not found. Please check the Student ID.' : 'Error loading data. Please try again.',
                style: typography.bodyMedium.copyWith(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
      data: (data) => Column(
        children: [
          _StudentCard(student: data.student, colors: colors, typography: typography),
          const Gap(16),
          _AttendanceCard(records: data.attendance, colors: colors, typography: typography),
          const Gap(16),
          _FeeCard(records: data.finance, colors: colors, typography: typography),
          const Gap(16),
          _ReportsCard(reports: data.reports, colors: colors, typography: typography),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.colors, required this.typography});
  final Map<String, dynamic> student;
  final dynamic colors;
  final dynamic typography;

  @override
  Widget build(BuildContext context) {
    final photoUrl = student['photoUrl'] as String?;
    final name = student['fullName'] as String? ?? 'Unknown';
    final grade = student['grade'] as String? ?? '';
    final admNo = student['studentId'] as String? ?? '';
    final guardian = student['guardianName'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colors.primary.withValues(alpha: 0.15),
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? Text(name.isNotEmpty ? name[0] : 'S', style: typography.h3.copyWith(color: colors.primary))
                : null,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: typography.h4),
                Text('$grade • $admNo', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                if (guardian.isNotEmpty)
                  Text('Guardian: $guardian', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('Active', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.records, required this.colors, required this.typography});
  final List<dynamic> records;
  final dynamic colors;
  final dynamic typography;

  @override
  Widget build(BuildContext context) {
    int present = 0, absent = 0, late = 0;
    for (final r in records) {
      final status = (r['status'] as String? ?? '').toLowerCase();
      if (status == 'present') { present++; }
      else if (status == 'absent') { absent++; }
      else if (status == 'late') { late++; }
    }
    final total = records.length;
    final rate = total > 0 ? (present / total * 100).toInt() : 0;

    return _SectionCard(
      icon: LucideIcons.calendarCheck2,
      title: 'Attendance (Last 30 Days)',
      iconColor: Colors.blue,
      child: Column(
        children: [
          Row(
            children: [
              _StatBadge(label: 'Present', value: '$present', color: Colors.green),
              const Gap(12),
              _StatBadge(label: 'Absent', value: '$absent', color: Colors.red),
              const Gap(12),
              _StatBadge(label: 'Late', value: '$late', color: Colors.orange),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$rate%', style: typography.h3.copyWith(color: colors.primary)),
                  Text('Attendance Rate', style: typography.caption),
                ],
              ),
            ],
          ),
          if (records.isNotEmpty) ...[
            const Gap(16),
            const Divider(),
            const Gap(8),
            ...records.take(5).map((r) {
              final date = r['date'] as String?;
              final status = r['status'] as String? ?? '';
              final color = status == 'Present' ? Colors.green : status == 'Absent' ? Colors.red : Colors.orange;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const Gap(12),
                    Text(date != null ? DateFormat('dd MMM').format(DateTime.tryParse(date) ?? DateTime.now()) : '', style: typography.bodySmall),
                    const Spacer(),
                    Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({required this.records, required this.colors, required this.typography});
  final List<dynamic> records;
  final dynamic colors;
  final dynamic typography;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: LucideIcons.wallet,
      title: 'Fee History',
      iconColor: Colors.green,
      child: records.isEmpty
          ? Text('No fee records found', style: typography.bodySmall.copyWith(color: colors.textSecondary))
          : Column(
              children: records.take(6).map<Widget>((r) {
                final label = r['monthLabel'] as String? ?? '';
                final paid = (r['totalPaid'] as num?)?.toDouble() ?? 0;
                final due = (r['totalDue'] as num?)?.toDouble() ?? 0;
                final status = r['status'] as String? ?? 'Pending';
                final isPaid = status == 'Paid';
                final color = isPaid ? Colors.green : status == 'Partially Paid' ? Colors.orange : Colors.red;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: typography.bodyMediumSemiBold),
                            Text('Due: SAR ${due.toStringAsFixed(0)} • Paid: SAR ${paid.toStringAsFixed(0)}',
                                style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                        child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ReportsCard extends StatelessWidget {
  const _ReportsCard({required this.reports, required this.colors, required this.typography});
  final List<dynamic> reports;
  final dynamic colors;
  final dynamic typography;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: LucideIcons.fileBarChart,
      title: 'Academic Progress Reports',
      iconColor: Colors.purple,
      child: reports.isEmpty
          ? Text('No progress reports yet', style: typography.bodySmall.copyWith(color: colors.textSecondary))
          : Column(
              children: reports.take(5).map<Widget>((r) {
                final term = r['term'] as String? ?? '';
                final grades = (r['grades'] as List?) ?? [];
                final status = r['evaluationStatus'] as String? ?? '';
                final remarks = r['remarks'] as String? ?? '';
                final statusColor = status == 'Passed' ? Colors.green : Colors.red;
                double avg = 0;
                if (grades.isNotEmpty) {
                  avg = grades.fold<double>(0.0, (s, g) => s + ((g['mark'] as num?)?.toDouble() ?? 0)) / grades.length;
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(term, style: typography.bodyMediumSemiBold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text('Average: ${avg.toStringAsFixed(1)}%', style: typography.bodySmall.copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
                      if (remarks.isNotEmpty) ...[
                        const Gap(4),
                        Text('Remarks: $remarks', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                      ],
                      if (grades.isNotEmpty) ...[
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: grades.map<Widget>((g) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                              child: Text('${g['subject']}: ${g['mark']}', style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.iconColor, required this.child});
  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Gap(12),
              Text(title, style: context.typography.h4),
            ],
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
        Text(label, style: context.typography.caption),
      ],
    );
  }
}
