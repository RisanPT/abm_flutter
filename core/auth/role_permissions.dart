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
  teachers,
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
  });

  final String label;
  final String route;
  final IconData icon;
  final AppModule module;
  final String? mobileLabel;
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
  ),
  AppNavItem(
    label: 'Accounts',
    route: RouteNames.accounts,
    icon: LucideIcons.indianRupee,
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

final Map<String, Set<AppModule>> _rolePermissions = {
  AppRoles.itAdmin: AppModule.values.toSet(),
  AppRoles.headMaster: {
    AppModule.dashboard,
    AppModule.students,
    AppModule.classrooms,
    AppModule.attendance,
    AppModule.timetable,
    AppModule.accounts,
    AppModule.outstandingDues,
    AppModule.incomeEntry,
    AppModule.finance,
    AppModule.transport,
    AppModule.administration,
    AppModule.settings,
    AppModule.institutes,
  },
  AppRoles.teacher: {
    AppModule.students,
    AppModule.classrooms,
    AppModule.attendance,
    AppModule.progressReports,
    AppModule.timetable,
    AppModule.administration,
  },
  AppRoles.treasurer: {
    AppModule.dashboard,
    AppModule.students,
    AppModule.classrooms,
    AppModule.attendance,
    AppModule.timetable,
    AppModule.accounts,
    AppModule.outstandingDues,
    AppModule.incomeEntry,
    AppModule.finance,
    AppModule.transport,
    AppModule.administration,
    AppModule.settings,
  },
  AppRoles.staff: {
    AppModule.dashboard,
    AppModule.students,
    AppModule.classrooms,
    AppModule.attendance,
    AppModule.timetable,
    AppModule.accounts,
    AppModule.outstandingDues,
    AppModule.finance,
    AppModule.transport,
    AppModule.administration,
    AppModule.settings,
  },
};

extension RoleStringExtension on String {
  String get label {
    switch (this) {
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

  bool canAccess(AppModule module) {
    return _rolePermissions[this]?.contains(module) ?? false;
  }

  // Permission Logic Helpers based on the Roles Matrix image
  bool get canEditStudentData => this == AppRoles.itAdmin || this == AppRoles.headMaster || this == AppRoles.staff;
  bool get canEditAdministration => this == AppRoles.itAdmin || this == AppRoles.headMaster || this == AppRoles.staff;
  bool get canEditAttendance => this == AppRoles.itAdmin || this == AppRoles.headMaster || this == AppRoles.teacher;
  bool get canEditTimetable => this == AppRoles.itAdmin || this == AppRoles.headMaster;
  bool get canEditAccounts => this == AppRoles.itAdmin || this == AppRoles.treasurer || this == AppRoles.staff;
  bool get canEditFinance => this == AppRoles.itAdmin || this == AppRoles.treasurer;

  List<AppNavItem> get navigationItems {
    return kAppNavItems.where((item) => canAccess(item.module)).toList();
  }

  String get defaultRoute {
    if (canAccess(AppModule.dashboard)) {
      return RouteNames.dashboard;
    }
    return navigationItems.isNotEmpty ? navigationItems.first.route : RouteNames.dashboard;
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
  if (location.startsWith(RouteNames.attendanceReport) ||
      location.startsWith(RouteNames.teacherCheckIn)) {
    return AppModule.attendance;
  }
  return null;
}
