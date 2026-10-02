import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/settings/domain/permission_model.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Friendly labels + grouping for every module toggle.
const Map<AppModule, (String, IconData)> _moduleMeta = {
  AppModule.dashboard: ('Dashboard', LucideIcons.layoutDashboard),
  AppModule.students: ('Students', LucideIcons.users),
  AppModule.classrooms: ('Classrooms', LucideIcons.layers),
  AppModule.attendance: ('Attendance', LucideIcons.clipboardCheck),
  AppModule.timetable: ('Timetable', LucideIcons.calendarDays),
  AppModule.progressReports: ('Progress Reports', LucideIcons.fileBarChart),
  AppModule.teacherCheckIn: ('Staff Check-in', LucideIcons.userCheck),
  AppModule.homework: ('Homework', LucideIcons.bookMarked),
  AppModule.hifz: ('Hifz Tracker', LucideIcons.bookOpen),
  AppModule.exams: ('Exams & Results', LucideIcons.award),
  AppModule.studentLeave: ('Student Leave', LucideIcons.calendarOff),
  AppModule.studyMaterials: ('Study Materials', LucideIcons.folderOpen),
  AppModule.accounts: ('Accounts', LucideIcons.banknote),
  AppModule.outstandingDues: ('Outstanding Dues', LucideIcons.alertCircle),
  AppModule.incomeEntry: ('Income Entry', LucideIcons.trendingUp),
  AppModule.feeSetup: ('Fee Setup', LucideIcons.receipt),
  AppModule.expenditure: ('Expenditure', LucideIcons.wallet),
  AppModule.finance: ('Finance', LucideIcons.lineChart),
  AppModule.teachers: ('Teachers', LucideIcons.graduationCap),
  AppModule.transport: ('Transport', LucideIcons.bus),
  AppModule.administration: ('Administration', LucideIcons.settings2),
  AppModule.settings: ('Settings', LucideIcons.settings),
  AppModule.institutes: ('Institutes', LucideIcons.building2),
  AppModule.websiteManagement: ('Website', LucideIcons.globe),
};

const List<(String, List<AppModule>)> _groups = [
  ('Academics', [
    AppModule.dashboard, AppModule.students, AppModule.classrooms,
    AppModule.attendance, AppModule.timetable, AppModule.progressReports, AppModule.teacherCheckIn,
  ]),
  ('Student features', [
    AppModule.homework, AppModule.hifz, AppModule.exams,
    AppModule.studentLeave, AppModule.studyMaterials,
  ]),
  ('Finance', [
    AppModule.accounts, AppModule.outstandingDues, AppModule.incomeEntry,
    AppModule.feeSetup, AppModule.expenditure, AppModule.finance,
  ]),
  ('People & Admin', [
    AppModule.teachers, AppModule.transport, AppModule.administration,
    AppModule.settings, AppModule.institutes, AppModule.websiteManagement,
  ]),
];

class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({super.key});
  @override
  ConsumerState<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen> {
  // Editable roles (Super Admin / IT Admin are locked to avoid self-lockout).
  static const _roles = [
    AppRoles.headMaster,
    AppRoles.teacher,
    AppRoles.treasurer,
    AppRoles.staff,
    AppRoles.student,
  ];
  String _role = AppRoles.headMaster;

  Set<String> _permsFor(List<PermissionModel> all, String role) {
    final match = all.where((p) => p.role == role);
    if (match.isNotEmpty) return match.first.permissions.toSet();
    return (kDefaultRolePermissions[role] ?? const <String>{}).toSet();
  }

  Future<void> _toggle(String role, AppModule m, bool on, Set<String> current) async {
    final next = Set<String>.from(current);
    if (on) {
      next.add(m.name);
    } else {
      next.remove(m.name);
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(permissionControllerProvider.notifier).updatePermissions(role, next.toList());
      messenger.showSnackBar(const SnackBar(content: Text('Access updated.'), duration: Duration(milliseconds: 800)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(permissionControllerProvider);
    final isStudent = _role == AppRoles.student;

    // For the Student role only show the toggles admins are meant to control.
    final groups = isStudent
        ? [('Student features', kStudentControllableModules)]
        : _groups;

    return Scaffold(
      backgroundColor: colors.background,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AbmErrorView(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(permissionControllerProvider),
        ),
        data: (permissions) {
          final current = _permsFor(permissions, _role);
          final allForRole = groups.expand((g) => g.$2).toList();
          final enabledCount = allForRole.where((m) => current.contains(m.name)).length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AbmGradientHeader(
                  title: 'Role Permissions',
                  subtitle: 'Control what each role can access',
                ),
              ),
              // Role selector.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _roles.map((r) {
                        final sel = r == _role;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(r),
                            selected: sel,
                            onSelected: (_) => setState(() => _role = r),
                            selectedColor: colors.primary.withValues(alpha: 0.14),
                            labelStyle: TextStyle(
                              color: sel ? colors.primary : colors.textSecondary,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                            ),
                            shape: StadiumBorder(side: BorderSide(color: sel ? colors.primary : colors.border)),
                            backgroundColor: colors.cardBackground,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              // Summary + hint.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Icon(isStudent ? LucideIcons.userCog : LucideIcons.shieldCheck, size: 16, color: colors.textSecondary),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          isStudent
                              ? 'Features students see in their portal · $enabledCount of ${allForRole.length} on'
                              : '$_role · $enabledCount of ${allForRole.length} modules enabled',
                          style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.list(
                  children: [
                    for (final g in groups) ...[
                      _GroupCard(
                        title: g.$1,
                        modules: g.$2,
                        enabled: current,
                        onToggle: (m, on) => _toggle(_role, m, on, current),
                      ),
                      const Gap(12),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.modules, required this.enabled, required this.onToggle});
  final String title;
  final List<AppModule> modules;
  final Set<String> enabled;
  final void Function(AppModule, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: Text(title, style: context.typography.bodyMediumSemiBold.copyWith(color: colors.primary)),
          ),
          for (final m in modules) _row(context, m),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppModule m) {
    final colors = context.colors;
    final meta = _moduleMeta[m] ?? (m.name, LucideIcons.square);
    final on = enabled.contains(m.name);
    return SwitchListTile(
      contentPadding: const EdgeInsets.only(right: 4),
      dense: true,
      activeThumbColor: colors.primary,
      secondary: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: (on ? colors.primary : colors.textSecondary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(meta.$2, size: 18, color: on ? colors.primary : colors.textSecondary),
      ),
      title: Text(meta.$1, style: context.typography.bodyMedium.copyWith(color: colors.textPrimary)),
      value: on,
      onChanged: (v) => onToggle(m, v),
    );
  }
}
