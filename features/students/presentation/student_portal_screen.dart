import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/students/data/student_portal_repository.dart';
import 'package:abm_madrasa/features/students/presentation/report_card_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudentPortalScreen extends ConsumerWidget {
  const StudentPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(studentPortalProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentPortalProvider),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(studentPortalProvider)),
            data: (data) => _PortalBody(data: data),
          ),
        ),
      ),
    );
  }
}

class _PortalBody extends ConsumerWidget {
  const _PortalBody({required this.data});
  final StudentPortalData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(data: data)),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _StatRow(data: data, isWide: isWide),
              const Gap(22),
              if (isWide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _AttendanceCard(data: data)),
                      const Gap(20),
                      Expanded(child: _FeesCard(data: data)),
                    ],
                  ),
                )
              else ...[
                _AttendanceCard(data: data),
                const Gap(20),
                _FeesCard(data: data),
              ],
              const Gap(20),
              _ReportsCard(data: data),
              const Gap(20),
              _ProfileCard(profile: data.profile),
              const Gap(28),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.data});
  final StudentPortalData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final p = data.profile;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withValues(alpha: 0.82)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('My Portal', style: context.typography.bodyMedium.copyWith(color: Colors.white70)),
              const Spacer(),
              IconButton(
                tooltip: 'Log out',
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage: (p.photoUrl != null && p.photoUrl!.isNotEmpty) ? NetworkImage(p.photoUrl!) : null,
                child: (p.photoUrl == null || p.photoUrl!.isEmpty)
                    ? Text(_initials(p.fullName), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
                    : null,
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName,
                        style: context.typography.h3.copyWith(color: Colors.white),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Gap(4),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _pill('ID: ${p.admissionNumber}'),
                      _pill(p.grade),
                      if (p.shift != null && p.shift!.isNotEmpty) _pill(p.shift!),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length == 1 ? parts.first[0].toUpperCase() : (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.data, required this.isWide});
  final StudentPortalData data;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final a = data.attendance;
    final f = data.fees;
    final cards = [
      _StatCard(icon: LucideIcons.clipboardCheck, label: 'Attendance', value: '${a.percentage}%',
          tint: _attColor(a.percentage), sub: '${a.present}/${a.total} present'),
      _StatCard(icon: LucideIcons.calendarX, label: 'Days Absent', value: '${a.absent}',
          tint: const Color(0xFFDC2626), sub: 'of ${a.total} classes'),
      _StatCard(
          icon: LucideIcons.wallet,
          label: 'Fee Balance',
          value: 'SAR ${f.balance.toStringAsFixed(0)}',
          tint: f.arrears > 0
              ? const Color(0xFFDC2626)
              : (f.balance > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
          sub: f.arrears > 0
              ? 'incl. SAR ${f.arrears.toStringAsFixed(0)} arrears'
              : (f.advanceBalance > 0
                  ? 'SAR ${f.advanceBalance.toStringAsFixed(0)} advance credit'
                  : (f.balance > 0 ? 'Due' : 'All clear'))),
    ];
    if (isWide) {
      return Row(children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const Gap(16),
          Expanded(child: cards[i]),
        ]
      ]);
    }
    return Column(children: [
      cards[0],
      const Gap(12),
      Row(children: [Expanded(child: cards[1]), const Gap(12), Expanded(child: cards[2])]),
    ]);
  }

  static Color _attColor(int pct) =>
      pct >= 75 ? const Color(0xFF16A34A) : (pct >= 50 ? const Color(0xFFD97706) : const Color(0xFFDC2626));
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.tint, required this.sub});
  final IconData icon;
  final String label, value, sub;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: tint, size: 20),
          ),
          const Gap(14),
          Text(value, style: context.typography.h3.copyWith(color: colors.textPrimary)),
          const Gap(2),
          Text(label, style: context.typography.bodyMediumSemiBold),
          Text(sub, style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: colors.primary),
            const Gap(9),
            Text(title, style: context.typography.h4),
          ]),
          const Gap(14),
          child,
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.data});
  final StudentPortalData data;

  @override
  Widget build(BuildContext context) {
    final recs = data.recentAttendance;
    return _SectionCard(
      title: 'Recent Attendance',
      icon: LucideIcons.calendarCheck,
      child: recs.isEmpty
          ? _empty(context, 'No attendance recorded yet.')
          : Column(
              children: [
                for (final r in recs.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Icon(LucideIcons.circle, size: 8, color: _statusColor(r.status)),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            r.date != null ? DateFormat('EEE, dd MMM yyyy').format(r.date!) : '—',
                            style: context.typography.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(r.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(r.status,
                              style: context.typography.bodySmall.copyWith(
                                  color: _statusColor(r.status), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  static Color _statusColor(String s) {
    final v = s.toLowerCase();
    if (v.contains('present')) return const Color(0xFF16A34A);
    if (v.contains('late')) return const Color(0xFFD97706);
    if (v.contains('leave')) return const Color(0xFF2563EB);
    return const Color(0xFFDC2626);
  }
}

class _FeesCard extends StatelessWidget {
  const _FeesCard({required this.data});
  final StudentPortalData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = data.feeRecords;
    return _SectionCard(
      title: 'Fees',
      icon: LucideIcons.receipt,
      child: rows.isEmpty
          ? _empty(context, 'No fee records yet.')
          : Column(
              children: [
                for (final r in rows.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.monthLabel, style: context.typography.bodyMediumSemiBold),
                              Text('SAR ${r.totalPaid.toStringAsFixed(0)} / ${r.totalDue.toStringAsFixed(0)}',
                                  style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _feeColor(r.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(r.status,
                              style: context.typography.bodySmall
                                  .copyWith(color: _feeColor(r.status), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  static Color _feeColor(String s) =>
      s.toLowerCase() == 'paid' ? const Color(0xFF16A34A) : const Color(0xFFD97706);
}

class _ReportsCard extends StatelessWidget {
  const _ReportsCard({required this.data});
  final StudentPortalData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reports = data.reports;
    return _SectionCard(
      title: 'Progress Reports',
      icon: LucideIcons.fileBarChart,
      child: reports.isEmpty
          ? _empty(context, 'No progress reports published yet.')
          : Column(
              children: [
                for (final r in reports.take(6))
                  Container(
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
                            Expanded(
                              child: Text(
                                [r.term, r.academicYear].where((s) => s.isNotEmpty).join(' · '),
                                style: context.typography.bodyMediumSemiBold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Attendance ${r.attendanceRate.toStringAsFixed(0)}%',
                                  style: context.typography.bodySmall
                                      .copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
                            ),
                            const Gap(6),
                            IconButton(
                              tooltip: 'Download report card',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => shareReportCard(data.profile, r),
                              icon: Icon(LucideIcons.download, size: 18, color: colors.primary),
                            ),
                          ],
                        ),
                        if (r.grades.isNotEmpty) ...[
                          const Gap(10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final g in r.grades)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: context.typography.bodySmall.copyWith(color: colors.textPrimary),
                                      children: [
                                        TextSpan(text: '${g.subject}  '),
                                        TextSpan(
                                          text: '${g.mark}',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        TextSpan(
                                          text: g.grade.isNotEmpty ? '  (${g.grade})' : '',
                                          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (r.remarks.isNotEmpty) ...[
                          const Gap(10),
                          Text('“${r.remarks}”',
                              style: context.typography.bodySmall
                                  .copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Guardian', profile.guardianName),
      ('Contact', profile.parentContact),
      ('Gender', profile.gender),
      ('Blood Group', profile.bloodGroup),
      ('Address', profile.address),
    ].where((e) => (e.$2 ?? '').isNotEmpty && e.$2 != 'Not provided').toList();

    return _SectionCard(
      title: 'My Details',
      icon: LucideIcons.user,
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110,
                      child: Text(r.$1, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary))),
                  Expanded(child: Text(r.$2!, style: context.typography.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget _empty(BuildContext context, String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(child: Text(msg, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary))),
    );

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Gap(120),
        Icon(LucideIcons.wifiOff, size: 40, color: context.colors.textSecondary),
        const Gap(12),
        Center(child: Text('Could not load your portal', style: context.typography.h4)),
        const Gap(8),
        Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
