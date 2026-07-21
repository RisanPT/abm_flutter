import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/features/dashboard/domain/dashboard_stats_model.dart';
import 'package:abm_madrasa/features/dashboard/presentation/dashboard_controller.dart';
import 'package:abm_madrasa/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:abm_madrasa/shared/widgets/institute_banner_chip.dart';
import 'package:abm_madrasa/features/transportation/presentation/fleet_management_screen.dart';
import 'package:abm_madrasa/features/teachers/presentation/progress_report_upload_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final allowedModules = user != null
        ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role)
        : <String>{};
    final navItems = user?.role.navigationItems(allowedModules) ?? const <AppNavItem>[];
    final isTeacher = user?.role == AppRoles.teacher;
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: dashboardState.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context, ref, isTeacher: isTeacher),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isTeacher) ...[
                        _buildTeacherDashboard(context, stats, allowedModules),
                      ] else ...[
                        _buildStatsGrid(context, stats, allowedModules),
                        const Gap(24),
                        if (allowedModules.contains(AppModule.accounts.name) ||
                            allowedModules.contains(AppModule.finance.name)) ...[
                          _buildSegmentData(context, stats),
                          const Gap(24),
                        ],
                        if ((allowedModules.contains(AppModule.accounts.name) ||
                                allowedModules.contains(AppModule.finance.name)) &&
                            stats.monthlyFinanceData.length > 1) ...[
                          _buildFinanceChart(context, stats.monthlyFinanceData),
                          const Gap(24),
                        ],
                        _buildQuickActions(context, navItems),
                        const Gap(24),
                        _buildRecentActivity(context, stats.recentActivities),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, {required bool isTeacher}) {
    final colors = context.colors;
    final typography = context.typography;
    final user = ref.watch(authControllerProvider).value;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AbmPatternPainter(color: Colors.white.withValues(alpha: 0.03)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assalamu Alaikum,',
                          style: typography.caption.copyWith(
                            color: colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          user?.username ?? 'Admin',
                          style: typography.h2.copyWith(
                            color: colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isTeacher)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Teacher',
                              style: typography.caption.copyWith(
                                color: colors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: colors.secondary,
                    child: Text(
                      (user?.username ?? 'A')[0].toUpperCase(),
                      style: typography.h4.copyWith(color: colors.primary),
                    ),
                  ),
                ],
              ),
              if (!isTeacher) ...[
                const Gap(24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: colors.white.withValues(alpha: 0.5), size: 20),
                      const Gap(12),
                      Text(
                        'Search student, parent, or staff...',
                        style: typography.bodySmall.copyWith(
                          color: colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(16),
              const InstituteBannerChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherDashboard(
      BuildContext context, DashboardStats stats, Set<String> allowedModules) {
    final colors = context.colors;
    final typography = context.typography;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Morning' : now.hour < 17 ? 'Afternoon' : 'Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Good $greeting',
                      style: typography.caption.copyWith(color: colors.secondary),
                    ),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.sun, color: colors.secondary, size: 18),
                ],
              ),
              const Gap(10),
              Text(
                DateFormat('EEEE, d MMMM y').format(now),
                style: typography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const Gap(16),
              Row(
                children: [
                  _TeacherStatChip(
                    icon: LucideIcons.users,
                    value: stats.totalStudents.toString(),
                    label: 'Students',
                    color: colors.secondary,
                  ),
                  const Gap(12),
                  _TeacherStatChip(
                    icon: LucideIcons.calendarCheck,
                    value: '${stats.attendanceRate}%',
                    label: 'Attendance',
                    color: Colors.greenAccent.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),

        const Gap(24),

        Text('My Workspace', style: typography.h4.copyWith(fontWeight: FontWeight.bold)),
        const Gap(14),

        _TeacherActionCard(
          icon: LucideIcons.clipboardCheck,
          title: 'Mark Attendance',
          subtitle: "Record today's student attendance",
          color: const Color(0xFF2E7D32),
          onTap: () => context.push(RouteNames.attendance),
        ),
        const Gap(12),

        _TeacherActionCard(
          icon: LucideIcons.calendarDays,
          title: 'My Timetable',
          subtitle: 'View your class schedule',
          color: const Color(0xFF1B3D2F),
          onTap: () => context.push(RouteNames.timetable),
        ),
        const Gap(12),

        if (allowedModules.contains(AppModule.progressReports.name)) ...[
          _TeacherActionCard(
            icon: LucideIcons.fileBarChart,
            title: 'Progress Reports',
            subtitle: 'Upload grades and student results',
            color: Colors.teal.shade700,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgressReportUploadScreen()),
            ),
          ),
          const Gap(12),
        ],

        _TeacherActionCard(
          icon: LucideIcons.barChart2,
          title: 'Attendance Reports',
          subtitle: 'View monthly attendance overview',
          color: Colors.deepPurple.shade600,
          onTap: () => context.go(RouteNames.studentAttendanceReport),
        ),

        const Gap(24),

        // Mini stats row
        Text("Today's Overview", style: typography.h4.copyWith(fontWeight: FontWeight.bold)),
        const Gap(14),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Total',
                value: stats.totalStudents.toString(),
                icon: LucideIcons.users,
                color: colors.primary,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _MiniStatCard(
                label: 'Attendance',
                value: '${stats.attendanceRate}%',
                icon: LucideIcons.checkCircle2,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _MiniStatCard(
                label: 'Events',
                value: stats.upcomingEvents.toString().padLeft(2, '0'),
                icon: LucideIcons.bell,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),

        const Gap(20),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats, Set<String> allowedModules) {
    return GridView.extent(
      maxCrossAxisExtent: 250,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        StatCard(
          title: 'Total Students',
          value: stats.totalStudents.toString(),
          subtitle: 'Active members',
          icon: LucideIcons.users,
          color: const Color(0xFF2E7D32),
        ),
        StatCard(
          title: 'Attendance',
          value: '${stats.attendanceRate}%',
          subtitle: "Today's report",
          icon: LucideIcons.calendarCheck,
          color: const Color(0xFFC0A040),
        ),
        if (allowedModules.contains(AppModule.finance.name) ||
            allowedModules.contains(AppModule.accounts.name))
          StatCard(
            title: 'Fee Collected',
            value: NumberFormat.compactCurrency(symbol: 'SAR ').format(stats.feeCollectedThisMonth),
            subtitle: 'This month',
            icon: LucideIcons.wallet,
            color: Colors.blue.shade700,
            trend: stats.feeCollectedTrend.isNotEmpty ? stats.feeCollectedTrend : null,
          ),
        StatCard(
          title: 'Upcoming Events',
          value: stats.upcomingEvents.toString().padLeft(2, '0'),
          subtitle: 'Scheduled updates',
          icon: LucideIcons.bell,
          color: Colors.orange.shade700,
        ),
      ],
    );
  }

  Widget _buildSegmentData(BuildContext context, DashboardStats stats) {
    if (stats.segmentData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accounts Segmentation',
            style: context.typography.h4.copyWith(fontWeight: FontWeight.bold)),
        const Gap(16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: stats.segmentData.entries.map((entry) {
              final segment = entry.key;
              final data = entry.value;
              final net = data.income - data.expense;
              return SizedBox(
                width: 200,
                child: Card(
                  margin: const EdgeInsets.only(right: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(segment,
                            style: context.typography.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold)),
                        const Gap(12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Income:', style: context.typography.bodySmall),
                            Text('SAR ${data.income.toStringAsFixed(0)}',
                                style: context.typography.bodySmall.copyWith(
                                    color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Gap(4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Expense:', style: context.typography.bodySmall),
                            Text('SAR ${data.expense.toStringAsFixed(0)}',
                                style: context.typography.bodySmall.copyWith(
                                    color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Net:',
                                style: context.typography.bodySmall
                                    .copyWith(fontWeight: FontWeight.bold)),
                            Text('SAR ${net.toStringAsFixed(0)}',
                                style: context.typography.bodySmall.copyWith(
                                    color: net >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceChart(BuildContext context, List<MonthlyFinanceData> data) {
    final colors = context.colors;
    final typography = context.typography;

    final double maxRevenue =
        data.isEmpty ? 1000 : data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final double maxY = maxRevenue == 0 ? 1000 : maxRevenue * 1.2;

    return Container(
      padding: const EdgeInsets.only(top: 20, left: 10, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Revenue Overview',
                    style: typography.h4.copyWith(fontWeight: FontWeight.bold)),
                Icon(LucideIcons.trendingUp, color: colors.primary),
              ],
            ),
          ),
          const Gap(32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.length > 1) ? (data.length - 1).toDouble() : 5.0,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: colors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          value >= 0 && value < data.length
                              ? data[value.toInt()].month.split(' ')[0]
                              : '',
                          style: typography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == maxY && value != 0) return const SizedBox.shrink();
                        return Text(NumberFormat.compact().format(value),
                            style: typography.caption.copyWith(color: colors.textSecondary));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                        .toList(),
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, List<AppNavItem> navItems) {
    final typography = context.typography;
    final routes = navItems.map((item) => item.route).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: typography.h4.copyWith(fontWeight: FontWeight.bold)),
        const Gap(16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (routes.contains(RouteNames.attendance))
                _QuickActionItem(
                  icon: LucideIcons.clipboardCheck,
                  label: 'Attendance',
                  color: const Color(0xFFD6B64C),
                  onTap: () => context.push(RouteNames.attendance),
                ),
              if (routes.contains(RouteNames.timetable))
                _QuickActionItem(
                  icon: LucideIcons.calendarDays,
                  label: 'Timetable',
                  color: const Color(0xFF1B3D2F),
                  onTap: () => context.push(RouteNames.timetable),
                ),
              if (routes.contains(RouteNames.finance))
                _QuickActionItem(
                  icon: LucideIcons.banknote,
                  label: 'Collect Fee',
                  color: const Color(0xFFC0A040),
                  onTap: () => context.push(RouteNames.finance),
                ),
              if (routes.contains(RouteNames.students))
                _QuickActionItem(
                  icon: Icons.person_add_outlined,
                  label: 'Add Student',
                  color: const Color(0xFF1B3D2F),
                  onTap: () => context.push(RouteNames.addStudent),
                ),
              if (routes.contains(RouteNames.transport))
                _QuickActionItem(
                  icon: LucideIcons.bus,
                  label: 'Transport',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FleetManagementScreen()),
                  ),
                ),
              if (routes.contains(RouteNames.progressReports))
                _QuickActionItem(
                  icon: LucideIcons.fileSpreadsheet,
                  label: 'Upload Grades',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgressReportUploadScreen()),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<RecentActivity> activities) {
    if (activities.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: typography.h4.copyWith(fontWeight: FontWeight.bold)),
        const Gap(16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (_, index) => const Gap(12),
          itemBuilder: (context, index) {
            final activity = activities[index];
            final isFee = activity.type == 'Fee';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFee ? LucideIcons.wallet : LucideIcons.userPlus,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.title,
                            style: typography.bodyMediumSemiBold,
                            overflow: TextOverflow.ellipsis),
                        Text(activity.subtitle,
                            style:
                                typography.bodySmall.copyWith(color: colors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Gap(8),
                  Text(
                    DateFormat('MMM d').format(activity.time.toLocal()),
                    style: typography.caption,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Teacher-specific widgets ──────────────────────────────────────────────────

class _TeacherStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _TeacherStatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: typography.bodyLargeSemiBold.copyWith(color: Colors.white)),
              Text(label, style: typography.caption.copyWith(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TeacherActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: typography.bodyMediumSemiBold),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: colors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

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
          Icon(icon, color: color, size: 18),
          const Gap(8),
          Text(value,
              style: typography.h4.copyWith(color: color, fontWeight: FontWeight.bold)),
          const Gap(2),
          Text(label, style: typography.caption.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Admin Quick Action Item ───────────────────────────────────────────────────

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const Gap(8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: typography.bodySmallSemiBold.copyWith(
              fontSize: 11,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
