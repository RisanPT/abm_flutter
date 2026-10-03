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
  homework,
  hifz,
  exams,
  studyMaterials,
  studentLeave,
  transport,
  administration,
  settings,
  institutes,
  websiteManagement,
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

  AppNavItem copyWith({
    String? label,
    String? route,
    IconData? icon,
    AppModule? module,
    String? mobileLabel,
    List<AppNavItem>? children,
  }) =>
      AppNavItem(
        label: label ?? this.label,
        route: route ?? this.route,
        icon: icon ?? this.icon,
        module: module ?? this.module,
        mobileLabel: mobileLabel ?? this.mobileLabel,
        children: children ?? this.children,
      );
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
    children: [
      AppNavItem(
        label: 'Student Directory',
        route: RouteNames.students,
        icon: LucideIcons.users,
        module: AppModule.students,
      ),
      AppNavItem(
        label: 'Progress Reports',
        route: RouteNames.progressReports,
        icon: LucideIcons.fileBarChart,
        module: AppModule.progressReports,
      ),
      AppNavItem(
        label: 'Homework',
        route: RouteNames.homework,
        icon: LucideIcons.bookMarked,
        module: AppModule.homework,
      ),
      AppNavItem(
        label: 'Hifz Tracker',
        route: RouteNames.hifz,
        icon: LucideIcons.bookOpen,
        module: AppModule.hifz,
      ),
      AppNavItem(
        label: 'Exams & Results',
        route: RouteNames.exams,
        icon: LucideIcons.award,
        module: AppModule.exams,
      ),
      AppNavItem(
        label: 'Study Materials',
        route: RouteNames.materials,
        icon: LucideIcons.folderOpen,
        module: AppModule.studyMaterials,
      ),
      AppNavItem(
        label: 'Student Leaves',
        route: RouteNames.studentLeave,
        icon: LucideIcons.calendarOff,
        module: AppModule.studentLeave,
      ),
    ],
  ),
  AppNavItem(
    label: 'Timetable',
    route: RouteNames.timetable,
    icon: LucideIcons.calendarDays,
    module: AppModule.timetable,
    children: [
      AppNavItem(
        label: 'Timetable Planner',
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
      AppNavItem(
        label: 'Class Timetables',
        route: RouteNames.classTimetableView,
        icon: LucideIcons.clock,
        module: AppModule.timetable,
      ),
      AppNavItem(
        label: 'Classrooms',
        route: RouteNames.classrooms,
        icon: LucideIcons.layers,
        module: AppModule.classrooms,
      ),
    ],
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
        label: 'Staff Check-in',
        route: RouteNames.staffCheckin,
        icon: LucideIcons.userCheck,
        module: AppModule.teacherCheckIn,
      ),
      AppNavItem(
        label: 'Student Reports',
        route: RouteNames.studentAttendanceReport,
        icon: LucideIcons.fileText,
        module: AppModule.attendance,
      ),
      AppNavItem(
        label: 'Teacher Reports',
        route: RouteNames.teacherAttendanceReport,
        icon: LucideIcons.fileSpreadsheet,
        module: AppModule.attendance,
      ),
    ],
  ),
  AppNavItem(
    label: 'Finance & Accounts',
    route: RouteNames.finance,
    icon: LucideIcons.wallet,
    module: AppModule.finance,
    children: [
      AppNavItem(
        label: 'Madrassa Finance',
        route: RouteNames.finance,
        icon: LucideIcons.wallet,
        module: AppModule.finance,
      ),
      AppNavItem(
        label: 'Staff Payroll',
        route: RouteNames.payroll,
        icon: LucideIcons.banknote,
        module: AppModule.finance,
      ),
      AppNavItem(
        label: 'Accounts & Fees',
        route: RouteNames.accounts,
        icon: LucideIcons.receipt,
        module: AppModule.accounts,
      ),
      AppNavItem(
        label: 'Family Fees',
        route: RouteNames.familyFees,
        icon: LucideIcons.users,
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
        label: 'Fee Setup',
        route: RouteNames.feeSetup,
        icon: LucideIcons.fileCog,
        module: AppModule.feeSetup,
      ),
    ],
  ),
  AppNavItem(
    label: 'Teachers',
    route: RouteNames.teachers,
    icon: LucideIcons.graduationCap,
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
    icon: LucideIcons.shieldCheck,
    module: AppModule.administration,
    children: [
      AppNavItem(
        label: 'Admin Overview',
        route: RouteNames.admin,
        icon: LucideIcons.clapperboard,
        module: AppModule.administration,
      ),
      AppNavItem(
        label: 'User Permissions',
        route: RouteNames.permissions,
        icon: LucideIcons.key,
        module: AppModule.administration,
      ),
      AppNavItem(
        label: 'Data Backup',
        route: RouteNames.dataBackup,
        icon: LucideIcons.database,
        module: AppModule.administration,
      ),
      AppNavItem(
        label: 'Notifications',
        route: RouteNames.notifications,
        icon: LucideIcons.bell,
        module: AppModule.administration,
      ),
      AppNavItem(
        label: 'Institutes',
        route: RouteNames.institutes,
        icon: LucideIcons.building,
        module: AppModule.institutes,
      ),
      AppNavItem(
        label: 'Website Content',
        route: RouteNames.websiteContent,
        icon: LucideIcons.layout,
        module: AppModule.websiteManagement,
      ),
    ],
  ),
  AppNavItem(
    label: 'Settings',
    route: RouteNames.settings,
    icon: LucideIcons.settings,
    module: AppModule.settings,
    mobileLabel: 'Settings',
  ),
];

const Map<String, Set<String>> kDefaultRolePermissions = {
  AppRoles.superAdmin: {
    'dashboard',
    'students',
    'classrooms',
    'attendance',
    'timetable',
    'finance',
    'accounts',
    'outstandingDues',
    'incomeEntry',
    'feeSetup',
    'expenditure',
    'teachers',
    'teacherCheckIn',
    'progressReports',
    'homework',
    'hifz',
    'exams',
    'studyMaterials',
    'studentLeave',
    'transport',
    'administration',
    'settings',
    'institutes',
    'websiteManagement',
  },
  AppRoles.itAdmin: {
    'dashboard',
    'students',
    'classrooms',
    'attendance',
    'timetable',
    'finance',
    'accounts',
    'outstandingDues',
    'incomeEntry',
    'feeSetup',
    'expenditure',
    'teachers',
    'teacherCheckIn',
    'progressReports',
    'homework',
    'hifz',
    'exams',
    'studyMaterials',
    'studentLeave',
    'transport',
    'administration',
    'settings',
    'institutes',
    'websiteManagement',
  },
  AppRoles.headMaster: {
    'dashboard',
    'students',
    'classrooms',
    'attendance',
    'teacherCheckIn',
    'progressReports',
    'homework',
    'hifz',
    'exams',
    'studyMaterials',
    'studentLeave',
    'timetable',
    'teachers',
    'accounts',
    'outstandingDues',
    'incomeEntry',
    'feeSetup',
    'transport',
    'administration',
    'settings',
    'institutes',
  },
  AppRoles.principal: {
    'dashboard',
    'students',
    'classrooms',
    'attendance',
    'teacherCheckIn',
    'progressReports',
    'homework',
    'hifz',
    'exams',
    'studyMaterials',
    'studentLeave',
    'timetable',
    'teachers',
    'accounts',
    'outstandingDues',
    'incomeEntry',
    'feeSetup',
    'transport',
    'administration',
    'settings',
    'institutes',
  },
  AppRoles.treasurer: {
    'dashboard',
    'students',
    'classrooms',
    'attendance',
    'timetable',
    'accounts',
    'outstandingDues',
    'incomeEntry',
    'finance',
    'feeSetup',
    'transport',
    'administration',
    'settings',
  },
  AppRoles.staff: {
    'dashboard',
    'students',
    'classrooms',
    'attendance',
    'homework',
    'hifz',
    'exams',
    'studyMaterials',
    'studentLeave',
    'timetable',
    'accounts',
    'outstandingDues',
    'finance',
    'transport',
    'administration',
    'settings',
  },
  AppRoles.teacher: {
    'students',
    'classrooms',
    'attendance',
    'teacherCheckIn',
    'progressReports',
    'homework',
    'hifz',
    'exams',
    'studyMaterials',
    'studentLeave',
    'timetable',
    'administration',
  },
  // Student self-service features the admin can toggle from Module Permissions.
  AppRoles.student: {
    'hifz',
    'homework',
    'exams',
    'studentLeave',
    'studyMaterials',
  },
};

/// The student-facing modules an admin can switch on/off for students.
const List<AppModule> kStudentControllableModules = [
  AppModule.hifz,
  AppModule.homework,
  AppModule.exams,
  AppModule.studentLeave,
  AppModule.studyMaterials,
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
    final effective = allowedModules.isNotEmpty ? allowedModules : (kDefaultRolePermissions[this] ?? {});
    return effective.contains(module.name);
  }

  // Permission Logic Helpers based on dynamic modules
  bool canEditStudentData(Set<String> allowedModules) => canAccess(AppModule.students, allowedModules);
  bool canEditAdministration(Set<String> allowedModules) => canAccess(AppModule.administration, allowedModules);
  bool canEditAttendance(Set<String> allowedModules) => canAccess(AppModule.attendance, allowedModules);
  // Timetable VIEW follows the module (teachers can see their schedule), but
  // CREATE / EDIT / DELETE is admin-only — mirrors the server write roles and
  // keeps schedule changes out of teacher interfaces.
  bool get canManageTimetable =>
      this == AppRoles.superAdmin || this == AppRoles.itAdmin || this == AppRoles.headMaster;
  bool canEditTimetable(Set<String> allowedModules) => canManageTimetable;
  // Attendance date scope: admins / head master may backfill past days; a plain
  // teacher can only mark attendance for TODAY (mirrors the server date-lock).
  bool get canBackfillAttendance =>
      this == AppRoles.superAdmin || this == AppRoles.itAdmin || this == AppRoles.headMaster;
  bool canEditAccounts(Set<String> allowedModules) => canAccess(AppModule.accounts, allowedModules);
  bool canEditFinance(Set<String> allowedModules) => canAccess(AppModule.finance, allowedModules);

  List<AppNavItem> navigationItems(Set<String> allowedModules) {
    final effective = allowedModules.isNotEmpty ? allowedModules : (kDefaultRolePermissions[this] ?? {});
    final result = <AppNavItem>[];

    for (final item in kAppNavItems) {
      if (item.children != null && item.children!.isNotEmpty) {
        final accessibleChildren = item.children!
            .where((child) => canAccess(child.module, effective))
            .toList();

        if (canAccess(item.module, effective) || accessibleChildren.isNotEmpty) {
          result.add(item.copyWith(children: accessibleChildren));
        }
      } else {
        if (canAccess(item.module, effective)) {
          result.add(item);
        }
      }
    }

    return result;
  }

  String defaultRoute(Set<String> allowedModules) {
    // Students land on their own portal (no admin modules).
    if (this == AppRoles.student) {
      return RouteNames.studentPortal;
    }
    final effective = allowedModules.isNotEmpty ? allowedModules : (kDefaultRolePermissions[this] ?? {});
    // Teachers land straight on their own "My Classes" attendance view.
    if (this == AppRoles.teacher && canAccess(AppModule.attendance, effective)) {
      return RouteNames.attendance;
    }
    if (canAccess(AppModule.dashboard, effective)) {
      return RouteNames.dashboard;
    }
    final items = navigationItems(effective);
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
