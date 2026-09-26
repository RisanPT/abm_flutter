import 'dart:math' as math;

import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/notifications/data/notification_repository.dart';
import 'package:abm_madrasa/features/notifications/presentation/notifications_screen.dart';
import 'package:abm_madrasa/features/notifications/presentation/bug_report.dart';
import 'package:abm_madrasa/features/students/data/student_portal_repository.dart';
import 'package:abm_madrasa/features/students/presentation/report_card_pdf.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Theme (madrasa green + gold) — the EduPulse layout recoloured.
const _green = Color(0xFF1B3D2F);
const _greenMid = Color(0xFF2E5A46);
const _gold = Color(0xFFB8860B);
const _goldLight = Color(0xFFE2B961);

class StudentPortalScreen extends ConsumerStatefulWidget {
  const StudentPortalScreen({super.key});
  @override
  ConsumerState<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends ConsumerState<StudentPortalScreen> {
  int _tab = 1; // 0 = Schedule, 1 = Home, 2 = Fees

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(studentPortalProvider);
    return Scaffold(
      backgroundColor: colors.background,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SafeArea(child: _ErrorView(onRetry: () => ref.invalidate(studentPortalProvider))),
        data: (data) => switch (_tab) {
          0 => _ScheduleTab(profile: data.profile),
          2 => _FeesTab(data: data),
          _ => _HomeTab(data: data, goTab: (i) => setState(() => _tab = i)),
        },
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (_) => _BottomNav(index: _tab, onTap: (i) => setState(() => _tab = i)),
        orElse: () => null,
      ),
    );
  }
}

// ── Bottom navigation (elevated center) ──────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.only(top: 8, bottom: 8 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(context, 0, LucideIcons.calendarDays, 'Schedule'),
          _centerItem(context),
          _navItem(context, 2, LucideIcons.wallet, 'Fees'),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, int i, IconData icon, String label) {
    final active = index == i;
    final color = active ? _green : context.colors.textSecondary;
    return InkWell(
      onTap: () => onTap(i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const Gap(4),
            Text(label, style: context.typography.bodySmall.copyWith(color: color, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _centerItem(BuildContext context) {
    final active = index == 1;
    return GestureDetector(
      onTap: () => onTap(1),
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_green, _greenMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                border: Border.all(color: active ? _goldLight : Colors.transparent, width: 2),
              ),
              child: const Icon(LucideIcons.home, color: Colors.white, size: 24),
            ),
            const Gap(2),
            Text('Home', style: context.typography.bodySmall.copyWith(color: active ? _green : context.colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── HOME TAB ─────────────────────────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab({required this.data, required this.goTab});
  final StudentPortalData data;
  final ValueChanged<int> goTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: _green,
      onRefresh: () async {
        ref.invalidate(studentPortalProvider);
        ref.invalidate(studentTimetableProvider);
        ref.invalidate(myNotificationsProvider);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TopHeader(data: data)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AttendanceFeeCard(data: data, onPay: () => goTab(2)),
                const Gap(20),
                _UrgentCircular(onTap: () => _push(context, const NotificationsScreen())),
                _QuickServices(onTap: (a) => _onAction(context, ref, a)),
                const Gap(24),
                _TodayLiveClasses(onOpenSchedule: () => goTab(0)),
                const Gap(24),
                _PerformanceStanding(data: data, onViewAll: () => _push(context, _ResultsPage(reports: data.reports, profile: data.profile))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _onAction(BuildContext context, WidgetRef ref, String a) {
    switch (a) {
      case 'schedule':
        goTab(0);
        break;
      case 'fees':
        goTab(2);
        break;
      case 'results':
        _push(context, _ResultsPage(reports: data.reports, profile: data.profile));
        break;
      case 'materials':
      case 'kitab':
      case 'hifz':
        _push(context, _MaterialsPage());
        break;
      case 'announcements':
        _push(context, const NotificationsScreen());
        break;
      case 'academic':
        showAcademicInfoSheet(context, data.profile);
        break;
      case 'id':
        showStudentIdCard(context, data.profile);
        break;
      case 'profile':
        showProfileSheet(context, data.profile,
            onReportBug: () => showBugReportDialog(context, ref),
            onLogout: () => ref.read(authControllerProvider.notifier).logout());
        break;
    }
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}


// ── Palette for the services grid (matches the reference design) ──────────────
const _tileBlue = Color(0xFF2F6FED);
const _tileRed = Color(0xFFE5484D);
const _tilePurple = Color(0xFF8B5CF6);
const _tileTeal = Color(0xFF0EA5A4);
const _tileOrange = Color(0xFFE8833A);
const _tileSlate = Color(0xFF64748B);
const _cream = Color(0xFFFBF3DE);

int? _minsOf(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0].trim());
  final m = int.tryParse(parts[1].trim());
  if (h == null || m == null) return null;
  return h * 60 + m;
}

String _academicYearNow() {
  final n = DateTime.now();
  return n.month >= 6 ? '${n.year}–${n.year + 1}' : '${n.year - 1}–${n.year}';
}

// ── Top header: brand bar + academy + profile ─────────────────────────────────
class _TopHeader extends ConsumerWidget {
  const _TopHeader({required this.data});
  final StudentPortalData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = data.profile;
    final t = context.typography;
    final unread = ref.watch(unreadCountProvider);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_green, _greenMid]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              child: CustomPaint(painter: AbmPatternPainter(color: Colors.white.withValues(alpha: 0.04))),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _goldLight.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.mosque, color: _green, size: 22),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STUDENT PORTAL', style: t.bodySmall.copyWith(color: _goldLight, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                          Text('Anas Bin Malik Madrasa', style: t.bodyLargeSemiBold.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    _hIcon(context, LucideIcons.bell, badge: unread > 0,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                    const Gap(8),
                    _hIcon(context, LucideIcons.qrCode, gold: true, onTap: () => showStudentIdCard(context, p)),
                  ],
                ),
                const Gap(14),
                Row(
                  children: [
                    _softPill(context, _academicYearNow(), Colors.white.withValues(alpha: 0.12), Colors.white),
                    const Spacer(),
                    _softPill(context, 'STU · ${p.admissionNumber.isEmpty ? '—' : p.admissionNumber}', _goldLight.withValues(alpha: 0.22), _goldLight),
                  ],
                ),
                const Gap(16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => showProfileSheet(context, p,
                          onReportBug: () => showBugReportDialog(context, ref),
                          onLogout: () => ref.read(authControllerProvider.notifier).logout()),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _goldLight.withValues(alpha: 0.7), width: 2)),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white.withValues(alpha: 0.18),
                              backgroundImage: (p.photoUrl != null && p.photoUrl!.isNotEmpty) ? NetworkImage(p.photoUrl!) : null,
                              child: (p.photoUrl == null || p.photoUrl!.isEmpty)
                                  ? Text(_initials(p.fullName), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: -1, bottom: -1,
                            child: Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(color: _goldLight, shape: BoxShape.circle, border: Border.all(color: _green, width: 2)),
                              child: const Icon(LucideIcons.check, size: 9, color: _green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('As-salamu alaykum  ✨', style: t.bodySmall.copyWith(color: _goldLight, fontSize: 12)),
                          const Gap(1),
                          Text(p.fullName, style: t.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const Gap(6),
                          _softPill(context, [p.grade, if ((p.shift ?? '').isNotEmpty) p.shift!].join('  •  '), Colors.white.withValues(alpha: 0.14), Colors.white),
                        ],
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

Widget _hIcon(BuildContext context, IconData icon, {required VoidCallback onTap, bool badge = false, bool gold = false}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Material(
        color: gold ? _goldLight.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: gold ? _goldLight : Colors.white, size: 18)),
        ),
      ),
      if (badge)
        Positioned(right: 0, top: 0, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: _goldLight, shape: BoxShape.circle, border: Border.all(color: _green, width: 1.5)))),
    ],
  );
}

Widget _softPill(BuildContext context, String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: context.typography.bodySmall.copyWith(color: fg, fontSize: 11.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
    );

// ── Attendance + Fee card (overlaps the header) ───────────────────────────────
class _AttendanceFeeCard extends StatelessWidget {
  const _AttendanceFeeCard({required this.data, required this.onPay});
  final StudentPortalData data;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final a = data.attendance;
    final f = data.fees;
    final t = context.typography;
    final colors = context.colors;
    final ringColor = a.percentage >= 75 ? const Color(0xFF2E7D32) : (a.percentage >= 50 ? _gold : const Color(0xFFD32F2F));
    final attLabel = a.percentage >= 90 ? 'Exemplary' : (a.percentage >= 75 ? 'On track' : 'Needs focus');
    final hasDue = f.balance > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 54, height: 54,
                    child: CustomPaint(
                      painter: _RingPainter(a.percentage / 100, ringColor, colors.border, 6),
                      child: Center(child: Text('${a.percentage}%', style: t.bodyMediumSemiBold.copyWith(color: _green, fontSize: 13))),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ATTENDANCE', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 9.5, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
                        Text('${a.present}/${a.total} Days', style: t.bodyLargeSemiBold.copyWith(color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Row(children: [
                          Icon(LucideIcons.medal, size: 12, color: ringColor),
                          const Gap(3),
                          Flexible(child: Text(attLabel, style: t.bodySmall.copyWith(color: ringColor, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: colors.border),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Text('TUITION FEE', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 9.5, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
                    const Gap(6),
                    if (hasDue) _softPillLight('DUE SOON', _gold),
                  ]),
                  const Gap(2),
                  Text('SAR ${f.balance.toStringAsFixed(0)}', style: t.h4.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Gap(8),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onPay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasDue ? _green : const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(hasDue ? 'Pay Now' : 'View', style: t.bodySmallSemiBold.copyWith(color: Colors.white)),
                        const Gap(2),
                        const Icon(LucideIcons.chevronRight, size: 15, color: Colors.white),
                      ]),
                    ),
                  ),
                  const Gap(4),
                  Text(hasDue ? 'Balance outstanding' : 'All fees cleared', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _softPillLight(String text, Color color) => Builder(builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: context.typography.bodySmall.copyWith(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
    ));

// ── Urgent circular (top important announcement) ──────────────────────────────
class _UrgentCircular extends ConsumerWidget {
  const _UrgentCircular({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myNotificationsProvider);
    // Surface the first UNREAD Important notice as an urgent circular; nothing
    // shows once it has been read (or when there are no important notices).
    final ann = async.maybeWhen(
      data: (feed) {
        for (final n in feed.items) {
          if (n.isImportant && !n.read) return n;
        }
        return null;
      },
      orElse: () => null,
    );
    if (ann == null) return const SizedBox.shrink();
    final t = context.typography;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold.withValues(alpha: 0.35))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
                child: Icon(LucideIcons.megaphone, size: 19, color: _gold),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.circle, size: 7, color: _gold),
                        const Gap(5),
                        Text(ann.isImportant ? 'URGENT CIRCULAR' : 'CIRCULAR', style: t.bodySmall.copyWith(color: _gold, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (ann.createdAt != null) _softPillLight(DateFormat('dd MMM').format(ann.createdAt!), _gold),
                      ],
                    ),
                    const Gap(6),
                    Text(ann.title, style: t.bodyMediumSemiBold.copyWith(color: const Color(0xFF3A2E12))),
                    if (ann.body.isNotEmpty) ...[
                      const Gap(2),
                      Text(ann.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall.copyWith(color: const Color(0xFF6B5B33))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick services grid ───────────────────────────────────────────────────────
class _QuickServices extends ConsumerWidget {
  const _QuickServices({required this.onTap});
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final items = <(String, IconData, String, Color, int)>[
      ('hifz', LucideIcons.bookMarked, 'Hifz Tracker', _green, 0),
      ('schedule', LucideIcons.calendarDays, 'Schedule', _tileBlue, 0),
      ('results', LucideIcons.star, 'Results', _gold, 0),
      ('announcements', LucideIcons.mailOpen, 'Notices', _tileRed, unread),
      ('kitab', LucideIcons.bookCopy, 'Kitab & Portal', _tilePurple, 0),
      ('fees', LucideIcons.receipt, 'Fees', _tileTeal, 0),
      ('id', LucideIcons.contact, 'ID Pass', _tileOrange, 0),
      ('profile', LucideIcons.userCog, 'Profile', _tileSlate, 0),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.layoutGrid, size: 18, color: _green),
            const Gap(8),
            Text('Quick Services', style: context.typography.bodyLargeSemiBold),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: context.colors.border)),
              child: Text('Madrasa Hub', style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 11)),
            ),
          ],
        ),
        const Gap(14),
        for (int row = 0; row < items.length; row += 4) ...[
          if (row > 0) const Gap(12),
          Row(
            children: [
              for (int i = row; i < row + 4 && i < items.length; i++) ...[
                if (i > row) const Gap(12),
                Expanded(child: _svcTile(context, items[i].$1, items[i].$2, items[i].$3, items[i].$4, items[i].$5)),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _svcTile(BuildContext context, String id, IconData icon, String label, Color color, int badge) {
    return InkWell(
      onTap: () => onTap(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: color, size: 21),
                ),
                if (badge > 0)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _tileRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const Gap(7),
            Text(label, textAlign: TextAlign.center, style: context.typography.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Today's live classes ──────────────────────────────────────────────────────
class _TodayLiveClasses extends ConsumerWidget {
  const _TodayLiveClasses({required this.onOpenSchedule});
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentTimetableProvider);
    final t = context.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.clock, size: 18, color: _green),
            const Gap(8),
            Text("Today's Classes", style: t.bodyLargeSemiBold),
            const Spacer(),
            Text(DateFormat('EEE, hh:mm a').format(DateTime.now()), style: t.bodySmall.copyWith(color: _gold, fontWeight: FontWeight.w600)),
          ],
        ),
        const Gap(12),
        async.when(
          loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => _liveEmpty(context, 'Couldn’t load your classes.'),
          data: (tt) {
            if (tt.days.isEmpty) return _liveEmpty(context, 'No classes in the next two weeks.');
            final today = tt.days.firstWhere((d) => d.isToday, orElse: () => tt.days.first);
            final periods = today.periods;
            if (periods.isEmpty) return _liveEmpty(context, 'No classes scheduled today.');
            final now = DateTime.now().hour * 60 + DateTime.now().minute;
            int activeIdx = -1, nextIdx = -1;
            for (int i = 0; i < periods.length; i++) {
              final s = _minsOf(periods[i].startTime);
              final e = _minsOf(periods[i].endTime);
              if (s != null && e != null && now >= s && now < e) activeIdx = i;
              if (nextIdx < 0 && s != null && s > now) nextIdx = i;
            }
            final heroIdx = activeIdx >= 0 ? activeIdx : (nextIdx >= 0 ? nextIdx : 0);
            final followIdx = activeIdx >= 0 ? nextIdx : (nextIdx >= 0 && nextIdx + 1 < periods.length ? nextIdx + 1 : -1);
            final isLive = activeIdx >= 0;
            return Column(
              children: [
                _activeClassCard(context, today, periods[heroIdx], isLive),
                if (followIdx >= 0 && followIdx < periods.length) ...[
                  const Gap(12),
                  _nextClassRow(context, periods[followIdx], now),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _activeClassCard(BuildContext context, PortalDay day, PortalPeriod p, bool isLive) {
    final t = context.typography;
    final time = p.startTime.isEmpty ? 'Period ${p.period}' : '${p.startTime} - ${p.endTime}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isLive ? _gold : context.colors.border, width: isLive ? 1.6 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: (isLive ? const Color(0xFF2E7D32) : _green).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.circle, size: 7, color: isLive ? const Color(0xFF2E7D32) : _green),
                  const Gap(5),
                  Text(isLive ? 'NOW · ACTIVE' : 'UP NEXT', style: t.bodySmall.copyWith(color: isLive ? const Color(0xFF2E7D32) : _green, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
              const Spacer(),
              Text(time, style: t.bodySmall.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const Gap(10),
          Text(p.subjectName, style: t.h4.copyWith(fontWeight: FontWeight.w700)),
          const Gap(4),
          Row(children: [
            Icon(LucideIcons.user, size: 13, color: context.colors.textSecondary),
            const Gap(5),
            Flexible(child: Text(p.teacherName.isEmpty ? '—' : p.teacherName, style: t.bodySmall.copyWith(color: context.colors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Gap(10),
            _softPill(context, day.shift, _green.withValues(alpha: 0.08), _green),
          ]),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onOpenSchedule,
                    icon: const Icon(LucideIcons.fileText, size: 15),
                    label: const Text('Lesson Notes'),
                    style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onOpenSchedule,
                    icon: const Icon(LucideIcons.volume2, size: 15),
                    label: const Text('Full Schedule'),
                    style: OutlinedButton.styleFrom(foregroundColor: _green, side: BorderSide(color: _green.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextClassRow(BuildContext context, PortalPeriod p, int now) {
    final t = context.typography;
    final s = _minsOf(p.startTime);
    final inMin = s != null ? s - now : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.startTime.isEmpty ? 'P${p.period}' : p.startTime, style: t.bodyMediumSemiBold.copyWith(color: _green)),
            Text(p.endTime.isEmpty ? '' : p.endTime, style: t.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 10)),
          ]),
          const Gap(14),
          Container(width: 3, height: 32, decoration: BoxDecoration(color: _goldLight, borderRadius: BorderRadius.circular(3))),
          const Gap(12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.subjectName, style: t.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (p.teacherName.isNotEmpty) Text(p.teacherName, style: t.bodySmall.copyWith(color: context.colors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (inMin != null && inMin > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('In ${inMin}m', style: t.bodySmall.copyWith(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _liveEmpty(BuildContext context, String msg) => Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)),
        child: Center(child: Text(msg, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary))),
      );
}

// ── Performance standing ──────────────────────────────────────────────────────
class _PerformanceStanding extends StatelessWidget {
  const _PerformanceStanding({required this.data, required this.onViewAll});
  final StudentPortalData data;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final t = context.typography;
    final colors = context.colors;
    final reports = data.reports;
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.border)),
        child: Row(children: [
          Icon(LucideIcons.trophy, size: 20, color: _gold),
          const Gap(12),
          Expanded(child: Text('Your academic standing appears here once results are published.', style: t.bodySmall.copyWith(color: colors.textSecondary))),
        ]),
      );
    }
    final r = reports.first;
    final grades = r.grades;
    final gpa = grades.isEmpty ? 0.0 : grades.map((g) => g.mark.toDouble()).reduce((a, b) => a + b) / grades.length;
    final band = gpa >= 90 ? 'Distinction' : (gpa >= 80 ? 'Merit' : (gpa >= 70 ? 'Pass' : 'Developing'));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PERFORMANCE STANDING', style: t.bodySmall.copyWith(color: _gold, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                  const Gap(2),
                  Text('Academic Standing', style: t.h4.copyWith(fontWeight: FontWeight.w700)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.award, size: 13, color: _gold), const Gap(4),
                    Text([r.term, r.academicYear].where((s) => s.isNotEmpty).join(' · '), style: t.bodySmallSemiBold.copyWith(color: _gold)),
                  ]),
                ]),
              ),
            ],
          ),
          const Gap(14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)), child: const Icon(LucideIcons.graduationCap, size: 17, color: Colors.white)),
              const Gap(10),
              Expanded(child: Text('Cumulative Madrasa GPA', style: t.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('${gpa.toStringAsFixed(1)}%', style: t.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
              const Gap(6),
              _softPillLight(band, _gold),
            ]),
          ),
          const Gap(12),
          for (int i = 0; i < grades.length; i++) ...[
            if (i > 0) const Gap(12),
            _subjectBar(context, grades[i], i.isEven ? const Color(0xFF2E7D32) : _gold),
          ],
          const Gap(14),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: _gold.withValues(alpha: 0.3))),
              child: Row(children: [
                Icon(LucideIcons.target, size: 16, color: _gold),
                const Gap(10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('VIEW REPORT CARDS', style: t.bodySmall.copyWith(color: _gold, fontSize: 9.5, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
                  Text('Download term results as PDF', style: t.bodySmallSemiBold.copyWith(color: const Color(0xFF3A2E12))),
                ])),
                const Icon(LucideIcons.chevronRight, size: 18, color: _gold),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectBar(BuildContext context, ReportGrade g, Color color) {
    final t = context.typography;
    final pct = (g.mark.toDouble().clamp(0, 100)) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(LucideIcons.circle, size: 8, color: color),
          const Gap(8),
          Expanded(child: Text(g.subject, style: t.bodySmall.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${g.mark}%', style: t.bodySmallSemiBold),
          if (g.grade.isNotEmpty) ...[const Gap(6), Text('(${g.grade})', style: t.bodySmallSemiBold.copyWith(color: _gold))],
        ]),
        const Gap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: context.colors.border, valueColor: AlwaysStoppedAnimation(color)),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.pct, this.color, this.track, this.stroke);
  final double pct;
  final Color color, track;
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    final bg = Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * pct.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.pct != pct || o.color != color;
}

Widget scheduleRow(BuildContext context, PortalPeriod p) {
  final time = p.startTime.isEmpty ? '—' : p.startTime;
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: context.colors.background, borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: context.typography.bodyMediumSemiBold.copyWith(color: _green)),
            if (p.endTime.isNotEmpty) Text(p.endTime, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 10)),
          ],
        ),
        const Gap(12),
        Container(width: 3, height: 34, decoration: BoxDecoration(color: _goldLight, borderRadius: BorderRadius.circular(3))),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.subjectName, style: context.typography.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (p.teacherName.isNotEmpty)
                Text(p.teacherName, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
          child: Text('P${p.period}', style: context.typography.bodySmall.copyWith(color: _green, fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      ],
    ),
  );
}

class _ScheduleTab extends ConsumerStatefulWidget {
  const _ScheduleTab({required this.profile});
  final PortalProfile profile;
  @override
  ConsumerState<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<_ScheduleTab> {
  int _sel = -1;
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentTimetableProvider);
    return Column(
      children: [
        _tabHeader(context, 'My Timetable', widget.profile.grade),
        Expanded(
          child: RefreshIndicator(
            color: _green,
            onRefresh: () async => ref.invalidate(studentTimetableProvider),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(children: [const Gap(80), _empty(context, 'Couldn’t load your timetable.')]),
              data: (tt) {
                if (tt.days.isEmpty) {
                  return ListView(children: [const Gap(80), _empty(context, 'No classes scheduled in the next two weeks.')]);
                }
                final todayIdx = tt.days.indexWhere((d) => d.isToday);
                final sel = (_sel >= 0 && _sel < tt.days.length) ? _sel : (todayIdx >= 0 ? todayIdx : 0);
                final day = tt.days[sel];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tt.days.length,
                        separatorBuilder: (_, _) => const Gap(8),
                        itemBuilder: (_, i) => _dayChip(context, tt.days[i], i == sel, () => setState(() => _sel = i)),
                      ),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Text(day.isToday ? 'Today' : (day.date != null ? DateFormat('EEEE, dd MMM').format(day.date!) : day.weekday), style: context.typography.bodyLargeSemiBold),
                        const Gap(8),
                        if (day.shift.isNotEmpty) _chip(context, day.shift, _green),
                      ],
                    ),
                    const Gap(12),
                    if (day.periods.isEmpty) _empty(context, 'No classes on this day.') else for (final p in day.periods) scheduleRow(context, p),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

Widget _dayChip(BuildContext context, PortalDay d, bool selected, VoidCallback onTap) {
  final wd = d.weekday.length >= 3 ? d.weekday.substring(0, 3) : d.weekday;
  final dayNum = d.date != null ? DateFormat('d').format(d.date!) : '';
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 54,
      decoration: BoxDecoration(
        gradient: selected ? const LinearGradient(colors: [_green, _greenMid], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: d.isToday && !selected ? _green : context.colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(wd, style: context.typography.bodySmall.copyWith(color: selected ? Colors.white70 : context.colors.textSecondary, fontSize: 11)),
          const Gap(2),
          Text(dayNum, style: context.typography.bodyLargeSemiBold.copyWith(color: selected ? Colors.white : context.colors.textPrimary)),
        ],
      ),
    ),
  );
}

// ── FEES TAB ─────────────────────────────────────────────────────────────────
class _FeesTab extends StatelessWidget {
  const _FeesTab({required this.data});
  final StudentPortalData data;
  @override
  Widget build(BuildContext context) {
    final f = data.fees;
    final rows = data.feeRecords;
    return Column(
      children: [
        _tabHeader(context, 'My Fees', data.profile.grade),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_green, _greenMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding Balance', style: context.typography.bodySmall.copyWith(color: Colors.white70)),
                    const Gap(4),
                    Text('SAR ${f.balance.toStringAsFixed(0)}', style: context.typography.h2.copyWith(color: Colors.white)),
                    const Gap(14),
                    Row(
                      children: [
                        Expanded(child: _feeStat(context, 'Paid', 'SAR ${f.totalPaid.toStringAsFixed(0)}')),
                        Expanded(child: _feeStat(context, 'Arrears', 'SAR ${f.arrears.toStringAsFixed(0)}')),
                        if (f.advanceBalance > 0) Expanded(child: _feeStat(context, 'Advance', 'SAR ${f.advanceBalance.toStringAsFixed(0)}')),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(20),
              Text('Fee History', style: context.typography.bodyLargeSemiBold),
              const Gap(12),
              if (rows.isEmpty)
                _empty(context, 'No fee records yet.')
              else
                for (final r in rows) _feeRow(context, r),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feeStat(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: context.typography.bodyMediumSemiBold.copyWith(color: _goldLight)),
          Text(label, style: context.typography.bodySmall.copyWith(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _feeRow(BuildContext context, FeeRow r) {
    final paid = r.status.toLowerCase() == 'paid';
    final color = paid ? const Color(0xFF2E7D32) : (r.status.toLowerCase() == 'waived' ? context.colors.textSecondary : _gold);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.monthLabel, style: context.typography.bodyMediumSemiBold),
                Text('SAR ${r.totalPaid.toStringAsFixed(0)} / ${r.totalDue.toStringAsFixed(0)}', style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
          _chip(context, r.status, color),
        ],
      ),
    );
  }
}

// ── Progress reports (Home) ──────────────────────────────────────────────────
Widget _tabHeader(BuildContext context, String title, String subtitle) => Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_green, _greenMid]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.typography.h3.copyWith(color: Colors.white)),
          if (subtitle.isNotEmpty) Text(subtitle, style: context.typography.bodySmall.copyWith(color: _goldLight)),
        ],
      ),
    );

Widget _chip(BuildContext context, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: context.typography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
    );

Widget _empty(BuildContext context, String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(child: Text(msg, textAlign: TextAlign.center, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary))),
    );

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  return parts.length == 1 ? parts.first[0].toUpperCase() : (parts[0][0] + parts[1][0]).toUpperCase();
}

// ── QR Student ID card ───────────────────────────────────────────────────────
void showStudentIdCard(BuildContext context, PortalProfile p) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_green, _greenMid]),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('STUDENT ID CARD', style: context.typography.bodySmall.copyWith(color: _goldLight, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const Gap(10),
            Text(p.fullName, style: context.typography.h4.copyWith(color: Colors.white), textAlign: TextAlign.center),
            Text('${p.grade}${p.admissionNumber.isNotEmpty ? '  ·  ${p.admissionNumber}' : ''}', style: context.typography.bodySmall.copyWith(color: Colors.white70)),
            const Gap(18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: QrImageView(
                data: 'ABM|${p.admissionNumber.isNotEmpty ? p.admissionNumber : p.fullName}|${p.grade}',
                size: 176,
                padding: EdgeInsets.zero,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _green),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _green),
              ),
            ),
            const Gap(16),
            if ((p.parentContact ?? '').isNotEmpty) _idRow(context, 'Contact', p.parentContact!),
            if ((p.address ?? '').isNotEmpty) _idRow(context, 'Address', p.address!),
            const Gap(6),
            Text('Show this code for quick identification & attendance', textAlign: TextAlign.center, style: context.typography.bodySmall.copyWith(color: Colors.white60, fontSize: 11)),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _idRow(BuildContext context, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 76, child: Text(label, style: context.typography.bodySmall.copyWith(color: Colors.white60))),
          Expanded(child: Text(value, style: context.typography.bodySmall.copyWith(color: Colors.white), textAlign: TextAlign.right)),
        ],
      ),
    );

// ── Academic & personal info sheet ───────────────────────────────────────────
void showAcademicInfoSheet(BuildContext context, PortalProfile p) => showProfileSheet(context, p);

void showProfileSheet(BuildContext context, PortalProfile p, {VoidCallback? onLogout, VoidCallback? onReportBug}) {
  String? d(DateTime? x) => x != null ? DateFormat('dd MMM yyyy').format(x) : null;
  final rows = <(String, String?)>[
    ('Class', p.grade),
    ('Shift', p.shift),
    ('Admission No.', p.admissionNumber),
    ('Date of Birth', d(p.dateOfBirth)),
    ('Gender', p.gender),
    ('Blood Group', p.bloodGroup),
    ('Guardian', p.guardianName),
    ('Contact', p.parentContact),
    ('Guardian Iqama', p.parentIqamaId),
    ('Address', p.address),
    ('Admitted On', d(p.admissionDate)),
  ].where((e) => (e.$2 ?? '').isNotEmpty && e.$2 != 'Not provided').toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(4)))),
          const Gap(16),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _green.withValues(alpha: 0.1),
                backgroundImage: (p.photoUrl != null && p.photoUrl!.isNotEmpty) ? NetworkImage(p.photoUrl!) : null,
                child: (p.photoUrl == null || p.photoUrl!.isEmpty) ? Text(_initials(p.fullName), style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 18)) : null,
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName, style: context.typography.h4),
                    Text('${p.grade}${p.admissionNumber.isNotEmpty ? '  ·  ${p.admissionNumber}' : ''}', style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Gap(18),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, child: Text(r.$1, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary))),
                  Expanded(child: Text(r.$2!, style: context.typography.bodyMedium)),
                ],
              ),
            ),
          if (onReportBug != null) ...[
            const Gap(18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onReportBug();
                },
                icon: const Icon(LucideIcons.bug, size: 16),
                label: const Text('Report a Bug', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
          if (onLogout != null) ...[
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
                icon: const Icon(LucideIcons.logOut, size: 16, color: Color(0xFFC0392B)),
                label: const Text('Log out', style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Color(0x33C0392B))),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// ── Pushed page scaffold ─────────────────────────────────────────────────────
class _PortalPage extends StatelessWidget {
  const _PortalPage({required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_green, _greenMid]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(6, MediaQuery.paddingOf(context).top + 6, 20, 20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.typography.h3.copyWith(color: Colors.white)),
                        if (subtitle.isNotEmpty) Text(subtitle, style: context.typography.bodySmall.copyWith(color: _goldLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
}

Widget _emptyFull(BuildContext context, IconData icon, String title, String subtitle) => Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: context.colors.textSecondary.withValues(alpha: 0.4)),
            const Gap(14),
            Text(title, style: context.typography.bodyLargeSemiBold.copyWith(color: context.colors.textSecondary)),
            const Gap(6),
            Text(subtitle, textAlign: TextAlign.center, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
          ],
        ),
      ),
    );

// ── Announcements ────────────────────────────────────────────────────────────
// ── Materials ────────────────────────────────────────────────────────────────
class _MaterialsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentMaterialsProvider);
    return _PortalPage(
      title: 'Study Materials',
      subtitle: 'Resources for your class',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _emptyFull(context, LucideIcons.wifiOff, 'Couldn’t load', 'Please try again.'),
        data: (list) => list.isEmpty
            ? _emptyFull(context, LucideIcons.bookOpen, 'No materials yet', 'Study materials shared by your teachers will appear here.')
            : RefreshIndicator(
                color: _green,
                onRefresh: () async => ref.invalidate(studentMaterialsProvider),
                child: ListView(padding: const EdgeInsets.all(16), children: [for (final m in list) _materialTile(context, m)]),
              ),
      ),
    );
  }
}

Widget _materialTile(BuildContext context, StudyMaterial m) {
  return InkWell(
    onTap: () => _launchUrl(context, m.url),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.border)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
            child: const Icon(LucideIcons.fileText, color: _green, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: context.typography.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (m.subject.isNotEmpty) Text(m.subject, style: context.typography.bodySmall.copyWith(color: _green)),
                if (m.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(m.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary)),
                  ),
              ],
            ),
          ),
          const Gap(8),
          const Icon(LucideIcons.externalLink, size: 18, color: _gold),
        ],
      ),
    ),
  );
}

Future<void> _launchUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open the link.')));
  }
}

// ── Results ──────────────────────────────────────────────────────────────────
class _ResultsPage extends StatelessWidget {
  const _ResultsPage({required this.reports, required this.profile});
  final List<ReportRow> reports;
  final PortalProfile profile;
  @override
  Widget build(BuildContext context) => _PortalPage(
        title: 'Results',
        subtitle: profile.grade,
        child: reports.isEmpty
            ? _emptyFull(context, LucideIcons.award, 'No results yet', 'Your exam results will appear here once published.')
            : ListView(padding: const EdgeInsets.all(16), children: [for (final r in reports) _resultCard(context, r, profile)]),
      );
}

Widget _resultCard(BuildContext context, ReportRow r, PortalProfile profile) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text([r.term, r.academicYear].where((s) => s.isNotEmpty).join(' · '), style: context.typography.bodyLargeSemiBold)),
            _chip(context, 'Att ${r.attendanceRate.toStringAsFixed(0)}%', _green),
            const Gap(4),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Download report card',
              onPressed: () => shareReportCard(profile, r),
              icon: const Icon(LucideIcons.download, size: 18, color: _green),
            ),
          ],
        ),
        if (r.grades.isNotEmpty) ...[
          const Gap(6),
          for (final g in r.grades)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(g.subject, style: context.typography.bodyMedium)),
                  Text('${g.mark}', style: context.typography.bodyMediumSemiBold),
                  const Gap(10),
                  Container(
                    constraints: const BoxConstraints(minWidth: 38),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(color: _gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(g.grade.isEmpty ? '—' : g.grade, style: context.typography.bodySmallSemiBold.copyWith(color: _gold)),
                  ),
                ],
              ),
            ),
        ],
        if (r.remarks.isNotEmpty) ...[
          const Gap(10),
          Text('“${r.remarks}”', style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ],
    ),
  );
}

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
        Center(child: TextButton.icon(onPressed: onRetry, icon: const Icon(LucideIcons.refreshCw, size: 16), label: const Text('Retry'))),
      ],
    );
  }
}
