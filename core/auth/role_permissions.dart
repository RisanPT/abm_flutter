import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum AppModule {
  dashboard,
  students,
  classrooms,
  attendance,
  timetable,
  finance,
  accounts,
  outstandingDues,
  incomeEntry,
  feeSetup,
  expenditure,
  teachers,
  teacherCheckIn,
  progressReports,
  transport,
  administration,
  settings,
  institutes,
}

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.module,
    this.mobileLabel,
    this.children,
  });

  final String label;
  final String route;
  final IconData icon;
  final AppModule module;
  final String? mobileLabel;
  final List<AppNavItem>? children;
}

const List<AppNavItem> kAppNavItems = [
  AppNavItem(
    label: 'Dashboard',
    route: RouteNames.dashboard,
    icon: LucideIcons.layoutDashboard,
    module: AppModule.dashboard,
  ),
  AppNavItem(
    label: 'Students',
    route: RouteNames.students,
    icon: LucideIcons.users,
    module: AppModule.students,
  ),
  AppNavItem(
    label: 'Classrooms',
    route: RouteNames.classrooms,
    icon: LucideIcons.layers,
    module: AppModule.classrooms,
  ),
  AppNavItem(
    label: 'Attendance',
    route: RouteNames.attendance,
    icon: LucideIcons.clipboardCheck,
    module: AppModule.attendance,
    children: [
      AppNavItem(
        label: 'Mark Attendance',
        route: RouteNames.attendance,
        icon: LucideIcons.checkSquare,
        module: AppModule.attendance,
      ),
      AppNavItem(
        label: 'Student Reports',
        route: RouteNames.studentAttendanceReport,
        icon: LucideIcons.bookOpen,
        module: AppModule.attendance,
      ),
      AppNavItem(
        label: 'Teacher Reports',
        route: RouteNames.teacherAttendanceReport,
        icon: LucideIcons.userCheck,
        module: AppModule.attendance,
      ),
    ],
  ),
  AppNavItem(
    label: 'My Attendance',
    route: RouteNames.staffCheckin,
    icon: LucideIcons.userCheck,
    module: AppModule.teacherCheckIn,
  ),
  AppNavItem(
    label: 'Progress Reports',
    route: RouteNames.progressReports,
    icon: LucideIcons.fileBarChart,
    module: AppModule.progressReports,
  ),

  AppNavItem(
    label: 'Timetable',
    route: RouteNames.timetable,
    icon: LucideIcons.calendarDays,
    module: AppModule.timetable,
    children: [
      AppNavItem(
        label: 'Timetable',
        route: RouteNames.timetable,
        icon: LucideIcons.calendarDays,
        module: AppModule.timetable,
      ),
      AppNavItem(
        label: 'Shift Planner',
        route: RouteNames.shiftPlanner,
        icon: LucideIcons.calendarCheck,
        module: AppModule.timetable,
      ),
    ],
  ),
  AppNavItem(
    label: 'Accounts',
    route: RouteNames.accounts,
    icon: LucideIcons.banknote,
    module: AppModule.accounts,
  ),
  AppNavItem(
    label: 'Outstanding Dues',
    route: RouteNames.outstandingDues,
    icon: LucideIcons.alertCircle,
    module: AppModule.outstandingDues,
  ),
  AppNavItem(
    label: 'Income Entry',
    route: RouteNames.incomeEntry,
    icon: LucideIcons.trendingUp,
    module: AppModule.incomeEntry,
  ),
  AppNavItem(
    label: 'Finance',
    route: RouteNames.finance,
    icon: LucideIcons.wallet,
    module: AppModule.finance,
  ),
  AppNavItem(
    label: 'Payroll',
    route: RouteNames.payroll,
    icon: LucideIcons.banknote,
    module: AppModule.finance,
  ),
  AppNavItem(
    label: 'Fee Setup',
    route: RouteNames.feeSetup,
    icon: LucideIcons.fileCog,
    module: AppModule.feeSetup,
  ),
  AppNavItem(
    label: 'Teachers',
    route: RouteNames.teachers,
    icon: LucideIcons.bookOpen,
    module: AppModule.teachers,
  ),
  AppNavItem(
    label: 'Transport',
    route: RouteNames.transport,
    icon: LucideIcons.bus,
    module: AppModule.transport,
  ),
  AppNavItem(
    label: 'Administration',
    route: RouteNames.admin,
    icon: LucideIcons.clapperboard,
    module: AppModule.administration,
  ),
  AppNavItem(
    label: 'Settings',
    route: RouteNames.settings,
    icon: LucideIcons.settings,
    module: AppModule.settings,
    mobileLabel: 'More',
  ),
  AppNavItem(
    label: 'Institutes',
    route: RouteNames.institutes,
    icon: LucideIcons.building,
    module: AppModule.institutes,
  ),
];

extension RoleStringExtension on String {
  String get label {
    switch (this) {
      case AppRoles.superAdmin:
        return 'Super Admin';
      case AppRoles.itAdmin:
        return 'IT Admin';
      case AppRoles.headMaster:
        return 'Head Master';
      case AppRoles.teacher:
        return 'Teacher';
      case AppRoles.treasurer:
        return 'Treasurer';
      case AppRoles.staff:
        return 'Staff';
      default:
        return this;
    }
  }

  bool canAccess(AppModule module, Set<String> allowedModules) {
    if (this == AppRoles.superAdmin || this == AppRoles.itAdmin) return true;
    return allowedModules.contains(module.name);
  }

  // Permission Logic Helpers based on dynamic modules
  bool canEditStudentData(Set<String> allowedModules) => canAccess(AppModule.students, allowedModules);
  bool canEditAdministration(Set<String> allowedModules) => canAccess(AppModule.administration, allowedModules);
  bool canEditAttendance(Set<String> allowedModules) => canAccess(AppModule.attendance, allowedModules);
  bool canEditTimetable(Set<String> allowedModules) => canAccess(AppModule.timetable, allowedModules);
  bool canEditAccounts(Set<String> allowedModules) => canAccess(AppModule.accounts, allowedModules);
  bool canEditFinance(Set<String> allowedModules) => canAccess(AppModule.finance, allowedModules);

  List<AppNavItem> navigationItems(Set<String> allowedModules) {
    return kAppNavItems.where((item) => canAccess(item.module, allowedModules)).toList();
  }

  String defaultRoute(Set<String> allowedModules) {
    // Teachers land straight on their own "My Classes" attendance view.
    if (this == AppRoles.teacher && canAccess(AppModule.attendance, allowedModules)) {
      return RouteNames.attendance;
    }
    if (canAccess(AppModule.dashboard, allowedModules)) {
      return RouteNames.dashboard;
    }
    final items = navigationItems(allowedModules);
    return items.isNotEmpty ? items.first.route : RouteNames.dashboard;
  }
}

String? roleFromLabel(String label) {
  for (final role in AppRoles.coreRoles) {
    if (role.label == label) {
      return role;
    }
  }
  return null;
}

AppModule? moduleForRoute(String location) {
  for (final item in kAppNavItems) {
    if (location == item.route || location.startsWith('${item.route}/')) {
      return item.module;
    }
  }
  if (location.startsWith(RouteNames.addStudent) ||
      location.startsWith(RouteNames.studentProfile) ||
      location.startsWith(RouteNames.editStudent)) {
    return AppModule.students;
  }
  if (location.startsWith(RouteNames.studentAttendanceReport) ||
      location.startsWith(RouteNames.teacherAttendanceReport)) {
    return AppModule.attendance;
  }
  return null;
}
