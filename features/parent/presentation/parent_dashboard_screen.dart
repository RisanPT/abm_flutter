import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart' show FeeLedger, LedgerMonth;
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/hifz/data/hifz_repository.dart' show HifzRecord;
import 'package:abm_madrasa/features/homework/data/homework_repository.dart' show Homework;
import 'package:abm_madrasa/features/notifications/data/notification_repository.dart';
import 'package:abm_madrasa/features/notifications/presentation/notifications_screen.dart';
import 'package:abm_madrasa/features/parent/data/parent_repository.dart';
import 'package:abm_madrasa/features/parent/presentation/fee_invoice_pdf.dart';
import 'package:abm_madrasa/features/students/data/student_portal_repository.dart'
    show PortalProfile;
import 'package:abm_madrasa/features/students/presentation/report_card_pdf.dart';
import 'package:abm_madrasa/features/students/presentation/student_portal_screen.dart' show showStudentIdCard;
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

// Brand Madrasa Colors
const _green = Color(0xFF1B3D2F);
const _greenMid = Color(0xFF2E5A46);
const _greenLight = Color(0xFFE8F3EE);
const _gold = Color(0xFFB8860B);
const _goldLight = Color(0xFFE2B961);

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  int _selectedChildIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final overviewAsync = ref.watch(parentOverviewProvider);
    final unread = ref.watch(unreadCountProvider);

    return SelectionArea(
      child: Scaffold(
      backgroundColor: colors.background,
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SafeArea(
          child: AbmErrorView(
            message: friendlyErrorMessage(e),
            onRetry: () => ref.invalidate(parentOverviewProvider),
          ),
        ),
        data: (overview) {
          if (overview.children.isEmpty) {
            return _buildEmptyState(context, unread);
          }

          final safeIndex = _selectedChildIndex.clamp(0, overview.children.length - 1);
          final selectedChild = overview.children[safeIndex];

          return RefreshIndicator(
            color: _green,
            onRefresh: () async {
              ref.invalidate(parentOverviewProvider);
              ref.invalidate(parentChildDetailsProvider(selectedChild.studentId));
              ref.invalidate(parentChildLedgerProvider(selectedChild.studentId));
              await ref.read(parentOverviewProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderBanner(
                    overview: overview,
                    selectedIndex: safeIndex,
                    unread: unread,
                    onSelectChild: (i) => setState(() => _selectedChildIndex = i),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: _ChildMainContent(child: selectedChild),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int unread) {
    return Column(
      children: [
        _buildSimpleHeader(context, unread),
        const Expanded(
          child: AbmEmptyState(
            icon: LucideIcons.users,
            title: 'No children linked',
            message: 'No active students are linked to this parent login yet. Please contact the madrasa office.',
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleHeader(BuildContext context, int unread) {
    return AbmGradientHeader(
      title: 'Parent Portal',
      subtitle: 'My Children',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BellButton(unread: unread),
          const Gap(8),
          AbmHeaderIconButton(
            icon: LucideIcons.logOut,
            tooltip: 'Logout',
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

// ── Header Banner with Islamic geometry & Child Switcher ──────────────────────
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({
    required this.overview,
    required this.selectedIndex,
    required this.unread,
    required this.onSelectChild,
  });

  final ParentOverview overview;
  final int selectedIndex;
  final int unread;
  final ValueChanged<int> onSelectChild;

  @override
  Widget build(BuildContext context) {
    final t = context.typography;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _greenMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: AbmPatternPainter(color: Colors.white.withValues(alpha: 0.05)),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? 8 : 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(LucideIcons.home, color: _goldLight, size: 20),
                        ),
                        const Gap(10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parent Portal',
                              style: t.h4.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Anas Bin Malik Madrasa',
                              style: t.bodySmall.copyWith(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _BellButton(unread: unread),
                        const Gap(8),
                        Consumer(
                          builder: (context, ref, _) => AbmHeaderIconButton(
                            icon: LucideIcons.logOut,
                            tooltip: 'Logout',
                            onTap: () => ref.read(authControllerProvider.notifier).logout(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(16),

                // Children Switcher (Tabs/Pills)
                if (overview.children.length > 1) ...[
                  Text(
                    'SELECT CHILD',
                    style: t.bodySmall.copyWith(
                      color: _goldLight,
                      letterSpacing: 1.2,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: overview.children.length,
                      separatorBuilder: (_, _) => const Gap(10),
                      itemBuilder: (context, i) {
                        final child = overview.children[i];
                        final isSelected = selectedIndex == i;
                        return _ChildTabPill(
                          child: child,
                          isSelected: isSelected,
                          onTap: () => onSelectChild(i),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.user, size: 13, color: _goldLight),
                            const Gap(6),
                            Text(
                              '1 Child Enrolled',
                              style: t.bodySmall.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildTabPill extends StatelessWidget {
  const _ChildTabPill({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final ParentChild child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.typography;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _goldLight : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              abmInitialsAvatar(context, child.fullName, radius: 16),
              const Gap(10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: t.bodyMediumSemiBold.copyWith(
                      color: isSelected ? _green : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    child.grade,
                    style: t.bodySmall.copyWith(
                      color: isSelected ? _greenMid : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (child.balance > 0) ...[
                const Gap(8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main Content for Selected Child ───────────────────────────────────────────
class _ChildMainContent extends ConsumerWidget {
  const _ChildMainContent({required this.child});
  final ParentChild child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = context.typography;
    final detailsAsync = ref.watch(parentChildDetailsProvider(child.studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Child Profile Card
        _HeroChildCard(child: child, detailsAsync: detailsAsync),
        const Gap(16),

        // 2. Fee Alert Banner if Due
        if (child.balance > 0) ...[
          _FeeDueAlertBanner(child: child),
          const Gap(16),
        ],

        // 3. Four Key Metric Cards
        _MetricsRow(child: child),
        const Gap(20),

        // 4. Section Title: Quick Services
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STUDENT SERVICES',
              style: t.bodySmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 11,
              ),
            ),
            Text(
              'Tap to view details',
              style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const Gap(10),

        // 5. 8 Touch Tiles (2x4 Grid)
        _QuickServicesGrid(child: child, detailsAsync: detailsAsync),
        const Gap(24),

        // 6. Recent Hifz Activity or Timetable Preview
        detailsAsync.maybeWhen(
          data: (details) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (details.hifzRecords.isNotEmpty) ...[
                _RecentHifzSnippet(record: details.hifzRecords.first, onOpenAll: () => _openHifzSheet(context, details)),
                const Gap(16),
              ],
              if (details.homework.isNotEmpty) ...[
                _ActiveHomeworkSnippet(
                  homeworkList: details.homework,
                  onOpenAll: () => _openHomeworkSheet(context, details),
                ),
              ],
            ],
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _openHifzSheet(BuildContext context, ParentChildDetails details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChildHifzSheet(details: details),
    );
  }

  void _openHomeworkSheet(BuildContext context, ParentChildDetails details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChildHomeworkSheet(details: details),
    );
  }
}

// ── Hero Child Card ────────────────────────────────────────────────────────────
class _HeroChildCard extends ConsumerWidget {
  const _HeroChildCard({required this.child, required this.detailsAsync});
  final ParentChild child;
  final AsyncValue<ParentChildDetails> detailsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              abmInitialsAvatar(context, child.fullName, radius: 28),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: t.h4.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            child.grade,
                            style: t.bodySmallSemiBold.copyWith(color: colors.primary, fontSize: 11),
                          ),
                        ),
                        const Gap(6),
                        Text(
                          '#${child.admissionNumber}',
                          style: t.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                        if (child.shift.isNotEmpty) ...[
                          const Gap(6),
                          Text('• ${child.shift}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.qrCode, color: _green, size: 24),
                tooltip: 'Student ID Card',
                onPressed: () {
                  detailsAsync.maybeWhen(
                    data: (d) => showStudentIdCard(context, d.profile),
                    orElse: () {
                      final p = PortalProfile(
                        fullName: child.fullName,
                        admissionNumber: child.admissionNumber,
                        grade: child.grade,
                        shift: child.shift,
                        parentContact: child.parentContact,
                      );
                      showStudentIdCard(context, p);
                    },
                  );
                },
              ),
            ],
          ),
          if (child.bloodGroup.isNotEmpty || child.guardianName.isNotEmpty) ...[
            const Gap(12),
            const Divider(height: 1),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (child.bloodGroup.isNotEmpty)
                  Row(
                    children: [
                      const Icon(LucideIcons.droplet, size: 14, color: Colors.redAccent),
                      const Gap(4),
                      Text('Blood: ${child.bloodGroup}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                if (child.lastHifzSabaq != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.bookOpen, size: 14, color: _gold),
                        const Gap(4),
                        Flexible(
                          child: Text(
                            'Sabaq: ${child.lastHifzSabaq}',
                            style: t.bodySmallSemiBold.copyWith(color: _green, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Fee Due Alert Banner ───────────────────────────────────────────────────────
class _FeeDueAlertBanner extends ConsumerWidget {
  const _FeeDueAlertBanner({required this.child});
  final ParentChild child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.typography;

    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openLedger(context, ref, child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                child: Icon(LucideIcons.alertCircle, color: Colors.red.shade700, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fee Balance Due', style: t.bodyMediumSemiBold.copyWith(color: Colors.red.shade900)),
                    Text(
                      child.arrears > 0 ? 'Includes overdue balance from prior months' : 'Current month fee is pending',
                      style: t.bodySmall.copyWith(color: Colors.red.shade700, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(sar(child.balance), style: t.bodyLargeSemiBold.copyWith(color: Colors.red.shade700)),
                  Text('Pay / Ledger >', style: t.bodySmall.copyWith(color: Colors.red.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLedger(BuildContext context, WidgetRef ref, ParentChild child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LedgerSheet(child: child),
    );
  }
}

// ── 4 Quick Metric Cards ───────────────────────────────────────────────────────
class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.child});
  final ParentChild child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final attPct = child.attendancePercentage > 0
        ? '${child.attendancePercentage}%'
        : (child.present + child.absent > 0
            ? '${((child.present / (child.present + child.absent)) * 100).round()}%'
            : '${child.present}d');

    return Row(
      children: [
        _MetricCard(
          label: 'Attendance',
          value: attPct,
          subtitle: '${child.present} Pres • ${child.absent} Abs',
          icon: LucideIcons.calendarCheck2,
          color: colors.green,
        ),
        const Gap(10),
        _MetricCard(
          label: 'Fees Status',
          value: child.balance > 0 ? sar(child.balance) : 'Cleared',
          subtitle: child.balance > 0 ? 'Balance Due' : 'All Paid',
          icon: LucideIcons.wallet,
          color: child.balance > 0 ? Colors.red.shade600 : colors.green,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.typography;
    final colors = context.colors;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
              ],
            ),
            const Gap(8),
            Text(
              value,
              style: t.bodyLargeSemiBold.copyWith(color: color, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              subtitle,
              style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 8 Touch Tiles (Services Hub Grid) ─────────────────────────────────────────
class _QuickServicesGrid extends ConsumerWidget {
  const _QuickServicesGrid({required this.child, required this.detailsAsync});
  final ParentChild child;
  final AsyncValue<ParentChildDetails> detailsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = [
      _ServiceItem(
        title: 'Hifz & Quran',
        subtitle: 'Sabaq & Tilawah',
        icon: LucideIcons.bookOpen,
        color: const Color(0xFF0F766E), // Teal
        onTap: () => _openHifz(context),
      ),
      _ServiceItem(
        title: 'Exam Results',
        subtitle: 'Report Cards PDF',
        icon: LucideIcons.award,
        color: const Color(0xFFD97706), // Amber
        onTap: () => _openReports(context),
      ),
      _ServiceItem(
        title: 'Homework & Diary',
        subtitle: 'Class Tasks',
        icon: LucideIcons.fileText,
        color: const Color(0xFF2563EB), // Blue
        badge: child.activeHomeworkCount > 0 ? '${child.activeHomeworkCount}' : null,
        onTap: () => _openHomework(context),
      ),
      _ServiceItem(
        title: 'Attendance & Leave',
        subtitle: 'Apply for Leave',
        icon: LucideIcons.calendarDays,
        color: const Color(0xFF059669), // Emerald
        badge: child.pendingLeaveCount > 0 ? '1 Pending' : null,
        onTap: () => _openAttendance(context),
      ),
      _ServiceItem(
        title: 'Class Timetable',
        subtitle: 'Daily Periods',
        icon: LucideIcons.clock,
        color: const Color(0xFF7C3AED), // Violet
        onTap: () => _openTimetable(context),
      ),
      _ServiceItem(
        title: 'Fee Ledger',
        subtitle: 'Dues & Receipts',
        icon: LucideIcons.receipt,
        color: const Color(0xFFDC2626), // Red
        onTap: () => _openLedger(context, ref),
      ),
      _ServiceItem(
        title: 'Student ID Card',
        subtitle: 'Digital QR Pass',
        icon: LucideIcons.contact,
        color: const Color(0xFF4B5563), // Slate
        onTap: () => _openIdCard(context),
      ),
      _ServiceItem(
        title: 'Announcements',
        subtitle: 'Madrasa Circulars',
        icon: LucideIcons.bellRing,
        color: const Color(0xFFE11D48), // Rose
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.05,
      ),
      itemCount: services.length,
      itemBuilder: (context, i) {
        final s = services[i];
        return _ServiceTile(service: s);
      },
    );
  }

  void _openHifz(BuildContext context) {
    detailsAsync.whenData((d) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ChildHifzSheet(details: d),
      );
    });
  }

  void _openReports(BuildContext context) {
    detailsAsync.whenData((d) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ChildReportsSheet(details: d),
      );
    });
  }

  void _openHomework(BuildContext context) {
    detailsAsync.whenData((d) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ChildHomeworkSheet(details: d),
      );
    });
  }

  void _openAttendance(BuildContext context) {
    detailsAsync.whenData((d) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ChildAttendanceLeaveSheet(child: child, details: d),
      );
    });
  }

  void _openTimetable(BuildContext context) {
    detailsAsync.whenData((d) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ChildTimetableSheet(details: d),
      );
    });
  }

  void _openLedger(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LedgerSheet(child: child),
    );
  }

  void _openIdCard(BuildContext context) {
    detailsAsync.maybeWhen(
      data: (d) => showStudentIdCard(context, d.profile),
      orElse: () {
        final p = PortalProfile(
          fullName: child.fullName,
          admissionNumber: child.admissionNumber,
          grade: child.grade,
          shift: child.shift,
          parentContact: child.parentContact,
        );
        showStudentIdCard(context, p);
      },
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});
  final _ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return Material(
      color: colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: service.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(service.icon, size: 20, color: service.color),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(
                      service.subtitle,
                      style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (service.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: service.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    service.badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Activity Snippets (Hifz & Homework) ────────────────────────────────────────
class _RecentHifzSnippet extends StatelessWidget {
  const _RecentHifzSnippet({required this.record, required this.onOpenAll});
  final HifzRecord record;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final dateStr = record.date != null ? DateFormat('dd MMM yyyy').format(record.date!) : 'Today';

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.bookOpen, size: 16, color: _green),
                  const Gap(6),
                  Text('Latest Quran Memorization', style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                ],
              ),
              InkWell(
                onTap: onOpenAll,
                child: Text('View History >', style: t.bodySmallSemiBold.copyWith(color: colors.primary, fontSize: 11)),
              ),
            ],
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sabaq: ${record.sabaqLabel}', style: t.bodyMediumSemiBold.copyWith(color: _green)),
                      const Gap(2),
                      Text(
                        'Date: $dateStr ${record.quality.isNotEmpty ? '• Quality: ${record.quality}' : ''}',
                        style: t.bodySmall.copyWith(color: _greenMid, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (record.quality.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _greenMid.withValues(alpha: 0.2)),
                    ),
                    child: Text(record.quality, style: t.bodySmallSemiBold.copyWith(color: _green, fontSize: 11)),
                  ),
              ],
            ),
          ),
          if (record.notes.isNotEmpty) ...[
            const Gap(8),
            Text('Ustadh Note: "${record.notes}"', style: t.bodySmall.copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _ActiveHomeworkSnippet extends StatelessWidget {
  const _ActiveHomeworkSnippet({required this.homeworkList, required this.onOpenAll});
  final List<Homework> homeworkList;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final topHw = homeworkList.first;

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.fileCheck2, size: 16, color: Colors.blue),
                  const Gap(6),
                  Text('Daily Class Homework', style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                ],
              ),
              InkWell(
                onTap: onOpenAll,
                child: Text('View All (${homeworkList.length}) >', style: t.bodySmallSemiBold.copyWith(color: colors.primary, fontSize: 11)),
              ),
            ],
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topHw.title, style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                      const Gap(2),
                      Text(
                        '${topHw.subject} ${topHw.dueDate != null ? '• Due ${DateFormat('dd MMM').format(topHw.dueDate!)}' : ''}',
                        style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (topHw.completed)
                  const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 20)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text('Pending', style: t.bodySmallSemiBold.copyWith(color: Colors.amber.shade900, fontSize: 10)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet: Hifz & Quran Memorization ──────────────────────────────────
class _ChildHifzSheet extends StatelessWidget {
  const _ChildHifzSheet({required this.details});
  final ParentChildDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _greenLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.bookOpen, size: 20, color: _green),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hifz & Quran Progress', style: t.h4.copyWith(color: colors.textPrimary)),
                        Text('${details.profile.fullName} • ${details.hifzRecords.length} records logged', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: details.hifzRecords.isEmpty
                  ? const AbmEmptyState(
                      icon: LucideIcons.bookOpen,
                      title: 'No Hifz records logged',
                      message: 'Memorization records will appear here once the teacher logs them.',
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 28 + MediaQuery.paddingOf(context).bottom),
                      itemCount: details.hifzRecords.length,
                      separatorBuilder: (_, _) => const Gap(10),
                      itemBuilder: (context, i) {
                        final h = details.hifzRecords[i];
                        final dStr = h.date != null ? DateFormat('EEEE, dd MMM yyyy').format(h.date!) : '-';
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dStr, style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
                                  if (h.quality.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _qualityColor(h.quality).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        h.quality,
                                        style: t.bodySmallSemiBold.copyWith(color: _qualityColor(h.quality), fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                              const Gap(8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Sabaq', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      h.sabaqLabel,
                                      style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                              if (h.sabqi.isNotEmpty) ...[
                                const Gap(6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Sabqi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const Gap(8),
                                    Text(h.sabqi, style: t.bodySmall.copyWith(color: colors.textPrimary)),
                                  ],
                                ),
                              ],
                              if (h.manzil.isNotEmpty) ...[
                                const Gap(6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Manzil', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const Gap(8),
                                    Text(h.manzil, style: t.bodySmall.copyWith(color: colors.textPrimary)),
                                  ],
                                ),
                              ],
                              if (h.notes.isNotEmpty) ...[
                                const Gap(8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Remarks: ${h.notes}', style: t.bodySmall.copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic)),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _qualityColor(String q) {
    return switch (q.toLowerCase()) {
      'excellent' => Colors.green,
      'good' => Colors.blue,
      'average' => Colors.orange,
      _ => Colors.redAccent,
    };
  }
}

// ── Bottom Sheet: Exam Results & Progress Reports with PDF Download ───────────
class _ChildReportsSheet extends StatelessWidget {
  const _ChildReportsSheet({required this.details});
  final ParentChildDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(LucideIcons.award, size: 20, color: Colors.amber.shade800),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exam Results & Progress Reports', style: t.h4.copyWith(color: colors.textPrimary)),
                        Text('${details.profile.fullName} • ${details.reports.length} report cards available', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: details.reports.isEmpty
                  ? const AbmEmptyState(
                      icon: LucideIcons.award,
                      title: 'No reports published',
                      message: 'Exam report cards will appear here once published by the madrasa administration.',
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      itemCount: details.reports.length,
                      separatorBuilder: (_, _) => const Gap(14),
                      itemBuilder: (context, i) {
                        final r = details.reports[i];
                        final totalMarks = r.grades.fold<num>(0, (s, g) => s + g.mark);
                        final avg = r.grades.isNotEmpty ? (totalMarks / r.grades.length).round() : 0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.term.isEmpty ? 'Term Exam' : r.term, style: t.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
                                      Text('Academic Year: ${r.academicYear.isEmpty ? '-' : r.academicYear}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _greenLight, borderRadius: BorderRadius.circular(10)),
                                    child: Text('$avg% Avg', style: t.bodyMediumSemiBold.copyWith(color: _green)),
                                  ),
                                ],
                              ),
                              const Gap(12),
                              // Marks Table
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      color: colors.background,
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text('Subject', style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary))),
                                          Expanded(child: Text('Marks', style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary), textAlign: TextAlign.center)),
                                          Expanded(child: Text('Grade', style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary), textAlign: TextAlign.right)),
                                        ],
                                      ),
                                    ),
                                    ...r.grades.map((g) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(g.subject, style: t.bodyMedium.copyWith(color: colors.textPrimary))),
                                          Expanded(child: Text('${g.mark}', style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary), textAlign: TextAlign.center)),
                                          Expanded(child: Text(g.grade, style: t.bodyMediumSemiBold.copyWith(color: colors.primary), textAlign: TextAlign.right)),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                              if (r.remarks.isNotEmpty) ...[
                                const Gap(10),
                                Text('Teacher Remarks: "${r.remarks}"', style: t.bodySmall.copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic)),
                              ],
                              const Gap(14),
                              // Download Official PDF Report Card
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(LucideIcons.downloadCloud, size: 16),
                                  label: const Text('Download Official PDF Report Card'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _green,
                                    side: const BorderSide(color: _green),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => shareReportCard(details.profile, r),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet: Homework & Diary ───────────────────────────────────────────
class _ChildHomeworkSheet extends StatelessWidget {
  const _ChildHomeworkSheet({required this.details});
  final ParentChildDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(LucideIcons.fileText, size: 20, color: Colors.blue.shade700),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Homework & Madrasa Diary', style: t.h4.copyWith(color: colors.textPrimary)),
                        Text('${details.profile.fullName} • ${details.profile.grade}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: details.homework.isEmpty
                  ? const AbmEmptyState(
                      icon: LucideIcons.fileText,
                      title: 'No homework assigned',
                      message: 'No active assignments for this classroom.',
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 28 + MediaQuery.paddingOf(context).bottom),
                      itemCount: details.homework.length,
                      separatorBuilder: (_, _) => const Gap(12),
                      itemBuilder: (context, i) {
                        final hw = details.homework[i];
                        final due = hw.dueDate != null ? DateFormat('EEEE, dd MMM yyyy').format(hw.dueDate!) : 'No due date';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: Text(hw.subject.isEmpty ? 'General' : hw.subject, style: t.bodySmallSemiBold.copyWith(color: Colors.blue.shade800, fontSize: 11)),
                                  ),
                                  if (hw.completed)
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.green),
                                        const Gap(4),
                                        Text('Completed', style: t.bodySmallSemiBold.copyWith(color: Colors.green, fontSize: 11)),
                                      ],
                                    ),
                                ],
                              ),
                              const Gap(8),
                              Text(hw.title, style: t.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
                              if (hw.description.isNotEmpty) ...[
                                const Gap(4),
                                Text(hw.description, style: t.bodyMedium.copyWith(color: colors.textSecondary)),
                              ],
                              const Gap(10),
                              Row(
                                children: [
                                  Icon(LucideIcons.calendar, size: 13, color: colors.textSecondary),
                                  const Gap(4),
                                  Text('Due: $due', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11)),
                                  if (hw.assignedByName.isNotEmpty) ...[
                                    const Gap(10),
                                    Text('• By: ${hw.assignedByName}', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11)),
                                  ],
                                ],
                              ),
                              if (hw.attachmentUrl.isNotEmpty) ...[
                                const Gap(10),
                                InkWell(
                                  onTap: () => launchUrl(Uri.parse(hw.attachmentUrl), mode: LaunchMode.externalApplication),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.paperclip, size: 14, color: Colors.blue),
                                      const Gap(4),
                                      Text('View Attached File', style: t.bodySmallSemiBold.copyWith(color: Colors.blue)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet: Attendance Calendar & Leave Application ────────────────────
class _ChildAttendanceLeaveSheet extends StatefulWidget {
  const _ChildAttendanceLeaveSheet({required this.child, required this.details});
  final ParentChild child;
  final ParentChildDetails details;

  @override
  State<_ChildAttendanceLeaveSheet> createState() => _ChildAttendanceLeaveSheetState();
}

class _ChildAttendanceLeaveSheetState extends State<_ChildAttendanceLeaveSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(LucideIcons.calendarCheck2, size: 20, color: Colors.teal.shade800),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance & Leaves', style: t.h4.copyWith(color: colors.textPrimary)),
                        Text(widget.details.profile.fullName, style: t.bodySmall.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabCtrl,
              labelColor: _green,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: _green,
              tabs: const [
                Tab(text: 'Attendance History'),
                Tab(text: 'Leave Requests'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Attendance History
                  _buildAttendanceTab(context, scroll),
                  // Tab 2: Leave Requests + Apply Button
                  _buildLeaveTab(context, scroll),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context, ScrollController scroll) {
    final colors = context.colors;
    final t = context.typography;
    final sum = widget.details.attendanceSummary;

    return ListView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 28 + MediaQuery.paddingOf(context).bottom),
      children: [
        // Attendance Summary Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(context, 'Rate', '${sum.percentage}%', colors.green),
              _statItem(context, 'Present', '${sum.present}', colors.green),
              _statItem(context, 'Absent', '${sum.absent}', Colors.red.shade600),
              _statItem(context, 'Total Days', '${sum.total}', colors.textSecondary),
            ],
          ),
        ),
        const Gap(16),
        Text('Daily Records', style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
        const Gap(8),
        if (widget.details.recentAttendance.isEmpty)
          const AbmEmptyState(
            icon: LucideIcons.calendar,
            title: 'No attendance records yet',
            message: 'Attendance entries will show up here daily.',
          )
        else
          ...widget.details.recentAttendance.map((a) {
            final dStr = a.date != null ? DateFormat('EEEE, dd MMM yyyy').format(a.date!) : '-';
            final isPres = a.status.toLowerCase() == 'present';
            final isLate = a.status.toLowerCase() == 'late';
            final statusColor = isPres ? colors.green : (isLate ? Colors.orange : Colors.red.shade600);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(isPres ? LucideIcons.checkCircle : (isLate ? LucideIcons.clock : LucideIcons.xCircle),
                          size: 16, color: statusColor),
                      const Gap(10),
                      Text(dStr, style: t.bodyMedium.copyWith(color: colors.textPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(a.status, style: t.bodySmallSemiBold.copyWith(color: statusColor, fontSize: 11)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLeaveTab(BuildContext context, ScrollController scroll) {
    final colors = context.colors;
    final t = context.typography;

    return ListView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 28 + MediaQuery.paddingOf(context).bottom),
      children: [
        // Action: Apply for Leave Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(LucideIcons.plusCircle, size: 18),
            label: Text('Apply for Leave for ${widget.child.fullName}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _openApplyLeaveDialog(context),
          ),
        ),
        const Gap(16),
        Text('Past Leave Requests', style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
        const Gap(8),
        if (widget.details.leaves.isEmpty)
          const AbmEmptyState(
            icon: LucideIcons.fileCheck,
            title: 'No leave applications',
            message: 'Tap the button above to request medical or family leave for your child.',
          )
        else
          ...widget.details.leaves.map((l) {
            final fromStr = l.fromDate != null ? DateFormat('dd MMM').format(l.fromDate!) : '-';
            final toStr = l.toDate != null ? DateFormat('dd MMM yyyy').format(l.toDate!) : '-';
            final statusColor = switch (l.status.toLowerCase()) {
              'approved' => Colors.green,
              'rejected' => Colors.redAccent,
              _ => Colors.orange,
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$fromStr — $toStr', style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(l.status, style: t.bodySmallSemiBold.copyWith(color: statusColor, fontSize: 11)),
                      ),
                    ],
                  ),
                  if (l.reason.isNotEmpty) ...[
                    const Gap(6),
                    Text('Reason: ${l.reason}', style: t.bodyMedium.copyWith(color: colors.textSecondary)),
                  ],
                  if (l.decisionNote.isNotEmpty) ...[
                    const Gap(6),
                    Text('Madrasa Note: "${l.decisionNote}"', style: t.bodySmall.copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  void _openApplyLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ApplyLeaveDialog(child: widget.child),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, Color color) {
    final t = context.typography;
    return Column(
      children: [
        Text(value, style: t.h4.copyWith(color: color, fontWeight: FontWeight.bold)),
        const Gap(2),
        Text(label, style: t.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ── Dialog: Apply for Student Leave ───────────────────────────────────────────
class _ApplyLeaveDialog extends ConsumerStatefulWidget {
  const _ApplyLeaveDialog({required this.child});
  final ParentChild child;

  @override
  ConsumerState<_ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends ConsumerState<_ApplyLeaveDialog> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason for leave.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(parentRepositoryProvider).submitLeave(
            studentId: widget.child.studentId,
            fromDate: _fromDate,
            toDate: _toDate,
            reason: reason,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave application submitted successfully!')),
        );
        ref.invalidate(parentChildDetailsProvider(widget.child.studentId));
        ref.invalidate(parentOverviewProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit leave: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return AlertDialog(
      title: Text('Apply for Leave', style: t.h4.copyWith(color: colors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Child: ${widget.child.fullName} (${widget.child.grade})', style: t.bodySmallSemiBold.copyWith(color: colors.primary)),
            const Gap(16),
            Text('From Date', style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
            const Gap(4),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.calendar, size: 16),
              label: Text(DateFormat('dd MMM yyyy').format(_fromDate)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (d != null) {
                  setState(() {
                    _fromDate = d;
                    if (_toDate.isBefore(d)) _toDate = d;
                  });
                }
              },
            ),
            const Gap(12),
            Text('To Date (Inclusive)', style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
            const Gap(4),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.calendar, size: 16),
              label: Text(DateFormat('dd MMM yyyy').format(_toDate)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _toDate.isBefore(_fromDate) ? _fromDate : _toDate,
                  firstDate: _fromDate,
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (d != null) setState(() => _toDate = d);
              },
            ),
            const Gap(14),
            Text('Reason for Leave', style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
            const Gap(4),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Fever & doctor appointment, family travel, etc.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
          onPressed: _submitting ? null : _submit,
          child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Application'),
        ),
      ],
    );
  }
}

// ── Bottom Sheet: Class Timetable ─────────────────────────────────────────────
class _ChildTimetableSheet extends StatelessWidget {
  const _ChildTimetableSheet({required this.details});
  final ParentChildDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(LucideIcons.calendar, size: 20, color: Colors.purple.shade800),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Class Timetable & Schedule', style: t.h4.copyWith(color: colors.textPrimary)),
                        Text('${details.profile.fullName} • ${details.profile.grade}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: details.timetable.isEmpty
                  ? const AbmEmptyState(
                      icon: LucideIcons.calendar,
                      title: 'No timetable scheduled',
                      message: 'Class periods will appear here once published.',
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 28 + MediaQuery.paddingOf(context).bottom),
                      itemCount: details.timetable.length,
                      separatorBuilder: (_, _) => const Gap(14),
                      itemBuilder: (context, i) {
                        final d = details.timetable[i];
                        final dStr = d.date != null ? DateFormat('EEEE, dd MMM').format(d.date!) : d.weekday;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: d.isToday ? _green : colors.border, width: d.isToday ? 2 : 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dStr, style: t.bodyLargeSemiBold.copyWith(color: d.isToday ? _green : colors.textPrimary)),
                                  if (d.isToday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Today', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const Gap(10),
                              ...d.periods.map((p) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: _greenLight, shape: BoxShape.circle),
                                      child: Text('${p.period}', style: t.bodySmallSemiBold.copyWith(color: _green, fontSize: 11)),
                                    ),
                                    const Gap(10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.subjectName, style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                                          if (p.teacherName.isNotEmpty)
                                            Text('Ustadh: ${p.teacherName}', style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    if (p.startTime.isNotEmpty)
                                      Text('${p.startTime} - ${p.endTime}', style: t.bodySmallSemiBold.copyWith(color: colors.primary, fontSize: 11)),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notifications Bell Button ──────────────────────────────────────────────────
class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AbmHeaderIconButton(
          icon: LucideIcons.bell,
          tooltip: 'Notifications',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Bottom Sheet: Fee Ledger ──────────────────────────────────────────────────
class _LedgerSheet extends ConsumerWidget {
  const _LedgerSheet({required this.child});
  final ParentChild child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = context.typography;
    final ledgerAsync = ref.watch(parentChildLedgerProvider(child.studentId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.receipt, size: 20, color: colors.primary),
                  const Gap(10),
                  Expanded(
                    child: Text('${child.fullName} — Fee Ledger',
                        style: t.h4.copyWith(color: colors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ledgerAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AbmErrorView(
                  message: friendlyErrorMessage(e),
                  onRetry: () => ref.invalidate(parentChildLedgerProvider(child.studentId)),
                ),
                data: (ledger) => _LedgerBody(ledger: ledger, scrollController: scrollController, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerBody extends StatelessWidget {
  const _LedgerBody({
    required this.ledger,
    required this.scrollController,
    required this.child,
  });
  final FeeLedger ledger;
  final ScrollController scrollController;
  final ParentChild child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final months = ledger.months.reversed.toList();
    final paidMonths = months.where((m) => m.totalPaid > 0 || m.status.toLowerCase() == 'paid').toList();

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + MediaQuery.paddingOf(context).bottom),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(child: _summaryCell(context, 'Overdue', sar(ledger.arrears), ledger.arrears > 0 ? Colors.red.shade600 : colors.green)),
              Container(width: 1, height: 36, color: colors.border),
              Expanded(child: _summaryCell(context, 'This month', sar(ledger.currentDue), ledger.currentDue > 0 ? colors.warning : colors.green)),
              Container(width: 1, height: 36, color: colors.border),
              Expanded(child: _summaryCell(context, 'Total due', sar(ledger.totalOutstanding), ledger.totalOutstanding > 0 ? Colors.red.shade600 : colors.green)),
            ],
          ),
        ),
        if (paidMonths.isNotEmpty) ...[
          const Gap(14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.downloadCloud, size: 16),
              label: Text('Download Latest Invoice (${paidMonths.first.monthLabel})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => printOrDownloadFeeInvoice(child: child, month: paidMonths.first),
            ),
          ),
        ],
        const Gap(16),
        Text('Month-by-month Invoices', style: t.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
        const Gap(8),
        ...months.map((m) => _MonthRow(month: m, child: child)),
        const Gap(18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(
                'To pay fees, submit payment receipts, or for billing questions, reach the accounts office:',
                style: t.bodySmall.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.phone, size: 15),
                    label: const Text('Call Office'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => launchUrl(Uri.parse('tel:+966500000000')),
                  ),
                  const Gap(10),
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.messageCircle, size: 15),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => launchUrl(Uri.parse('https://wa.me/966500000000'), mode: LaunchMode.externalApplication),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCell(BuildContext context, String label, String value, Color color) {
    final t = context.typography;
    return Column(
      children: [
        Text(value, style: t.bodyLargeSemiBold.copyWith(color: color)),
        const Gap(2),
        Text(label, style: t.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.child});
  final LedgerMonth month;
  final ParentChild child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final isPaidOrPartial = month.totalPaid > 0 || month.status.toLowerCase() == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month.monthLabel, style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                const Gap(2),
                Text('Paid ${sar(month.totalPaid)} of ${sar(month.totalDue)}',
                    style: t.bodySmall.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AbmStatusPill.status(context, month.waived ? 'Waived' : month.status),
              if (isPaidOrPartial) ...[
                const Gap(6),
                InkWell(
                  onTap: () => printOrDownloadFeeInvoice(child: child, month: month),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _greenLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.downloadCloud, size: 12, color: _green),
                        const Gap(4),
                        Text(
                          'PDF Invoice',
                          style: t.bodySmallSemiBold.copyWith(color: _green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
