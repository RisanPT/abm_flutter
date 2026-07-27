import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/auth/presentation/login_screen.dart';
import 'package:abm_madrasa/features/dashboard/presentation/dashboard_screen.dart';
import 'package:abm_madrasa/features/teachers/presentation/teacher_management_screen.dart';
import 'package:abm_madrasa/features/teachers/presentation/progress_report_upload_screen.dart';
import 'package:abm_madrasa/features/teachers/presentation/progress_report_list_screen.dart' as abm_progress_list;
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/student_list_screen.dart';
import 'package:abm_madrasa/features/students/presentation/add_student_screen.dart';
import 'package:abm_madrasa/features/students/presentation/student_profile_screen.dart';
import 'package:abm_madrasa/features/students/presentation/parent_portal_screen.dart';
import 'package:abm_madrasa/features/students/presentation/online_admission_screen.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_mark_screen.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_report_screen.dart';
import 'package:abm_madrasa/features/attendance/presentation/staff_checkin_screen.dart';

import 'package:abm_madrasa/features/timetable/presentation/timetable_screen.dart';
import 'package:abm_madrasa/features/timetable/presentation/shift_planner_screen.dart';
import 'package:abm_madrasa/features/timetable/presentation/class_timetable_view_screen.dart';
import 'package:abm_madrasa/features/teachers/presentation/teacher_dashboard_screen.dart';
import 'package:abm_madrasa/features/students/presentation/student_dashboard_screen.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_screen.dart';
import 'package:abm_madrasa/features/accounts/presentation/outstanding_dues_screen.dart';
import 'package:abm_madrasa/features/accounts/presentation/income_entry_screen.dart';
import 'package:abm_madrasa/features/accounts/presentation/fee_structure_setup_screen.dart';
import 'package:abm_madrasa/features/finance/presentation/finance_screen.dart' as expenditure;
import 'package:abm_madrasa/features/finance/presentation/payroll_screen.dart';
import 'package:abm_madrasa/features/events/presentation/event_list_screen.dart';
import 'package:abm_madrasa/features/settings/presentation/settings_screen.dart';
import 'package:abm_madrasa/features/settings/presentation/role_permissions_screen.dart';
import 'package:abm_madrasa/features/classrooms/presentation/classroom_management_screen.dart';
import 'package:abm_madrasa/features/user_admin/presentation/institute_management_screen.dart';
import 'package:abm_madrasa/features/transportation/presentation/fleet_management_screen.dart';
import 'package:abm_madrasa/shared/widgets/main_shell_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: RouteNames.login,
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final user = authState.value;

      final isLoggingIn = state.matchedLocation == RouteNames.login;
      final isPublic = state.matchedLocation == RouteNames.parentPortal ||
          state.matchedLocation == RouteNames.onlineAdmission;
      final module = moduleForRoute(state.matchedLocation);

      if (authState.isLoading) return null;

      // Public pages — no auth required
      if (isPublic) return null;

      if (user == null) {
        return isLoggingIn ? null : RouteNames.login;
      }

      final permState = ref.read(permissionControllerProvider);
      final allowedModules = ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role);

      if (isLoggingIn) {
        return user.role.defaultRoute(allowedModules);
      }

      // Only enforce module access once permissions have loaded — otherwise a
      // cold restart bounces the user off their current route to the dashboard.
      if (permState.hasValue && module != null && !user.role.canAccess(module, allowedModules)) {
        return user.role.defaultRoute(allowedModules);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // Public routes — no auth required
      GoRoute(
        path: RouteNames.parentPortal,
        builder: (context, state) => const ParentPortalScreen(),
      ),
      GoRoute(
        path: RouteNames.onlineAdmission,
        builder: (context, state) => const OnlineAdmissionScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShellScaffold(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.students,
            builder: (context, state) {
              final initialClass = state.extra as String?;
              return StudentListScreen(initialClass: initialClass);
            },
          ),
          GoRoute(
            path: RouteNames.classrooms,
            builder: (context, state) => const ClassroomManagementScreen(),
          ),
          GoRoute(
            path: RouteNames.addStudent,
            builder: (context, state) => const AddStudentScreen(),
          ),
          GoRoute(
            path: '${RouteNames.editStudent}/:id',
            builder: (context, state) {
              final student = state.extra is StudentModel
                  ? state.extra as StudentModel
                  : null;
              return AddStudentScreen(existingStudent: student);
            },
          ),
          GoRoute(
            path: '${RouteNames.studentProfile}/:id',
            name: RouteNames.studentProfile,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final student = state.extra is StudentModel
                  ? state.extra as StudentModel
                  : null;
              return StudentProfileScreen(
                studentId: id,
                initialStudent: student,
              );
            },
          ),
          GoRoute(
            path: RouteNames.attendance,
            builder: (context, state) {
              // A teacher marks attendance from their own "My Classes" view
              // (their scheduled classes), not the institute-wide class picker.
              final role = ref.read(authControllerProvider).value?.role;
              return role == AppRoles.teacher
                  ? TeacherDashboardScreen(teacherId: state.uri.queryParameters['teacherId'])
                  : const AttendanceMarkScreen();
            },
          ),
          GoRoute(
            path: '/attendance-report',
            redirect: (context, state) => RouteNames.studentAttendanceReport,
          ),
          GoRoute(
            path: RouteNames.studentAttendanceReport,
            builder: (context, state) => const AttendanceReportScreen(reportType: 'student'),
          ),
          GoRoute(
            path: RouteNames.teacherAttendanceReport,
            builder: (context, state) => const AttendanceReportScreen(reportType: 'teacher'),
          ),

          GoRoute(
            path: RouteNames.progressReports,
            builder: (context, state) => const abm_progress_list.ProgressReportListScreen(),
          ),
          GoRoute(
            path: RouteNames.addProgressReport,
            builder: (context, state) => const ProgressReportUploadScreen(),
          ),
          GoRoute(
            path: RouteNames.editProgressReport,
            builder: (context, state) {
              final report = state.extra as Map<String, dynamic>?;
              return ProgressReportUploadScreen(existingReport: report);
            },
          ),
          GoRoute(
            path: RouteNames.timetable,
            builder: (context, state) => const TimetableScreen(),
          ),
          GoRoute(
            path: RouteNames.shiftPlanner,
            builder: (context, state) => const ShiftPlannerScreen(),
          ),
          GoRoute(
            path: RouteNames.classTimetableView,
            builder: (context, state) => const ClassTimetableViewScreen(),
          ),
          GoRoute(
            path: RouteNames.teacherDashboard,
            builder: (context, state) => TeacherDashboardScreen(teacherId: state.uri.queryParameters['teacherId']),
          ),
          GoRoute(
            path: RouteNames.studentDashboard,
            builder: (context, state) => StudentDashboardScreen(
              studentId: state.uri.queryParameters['studentId'],
              classroom: state.uri.queryParameters['classroom'],
            ),
          ),
          GoRoute(
            path: RouteNames.accounts,
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: RouteNames.outstandingDues,
            builder: (context, state) => const OutstandingDuesScreen(),
          ),
          GoRoute(
            path: RouteNames.incomeEntry,
            builder: (context, state) => const IncomeEntryScreen(),
          ),
          GoRoute(
            path: RouteNames.finance,
            builder: (context, state) => const expenditure.FinanceScreen(),
          ),
          GoRoute(
            path: RouteNames.payroll,
            builder: (context, state) => const PayrollScreen(),
          ),
          GoRoute(
            path: RouteNames.staffCheckin,
            builder: (context, state) => const StaffCheckinScreen(),
          ),
          GoRoute(
            path: RouteNames.feeSetup,
            builder: (context, state) => const FeeStructureSetupScreen(),
          ),
          GoRoute(
            path: RouteNames.teachers,
            builder: (context, state) => const TeacherManagementScreen(),
          ),
          GoRoute(
            path: RouteNames.transport,
            builder: (context, state) => const FleetManagementScreen(),
          ),
          GoRoute(
            path: RouteNames.admin,
            builder: (context, state) => const EventListScreen(),
          ),
          GoRoute(
            path: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: RouteNames.permissions,
            builder: (context, state) => const RolePermissionsScreen(),
          ),
          GoRoute(
            path: RouteNames.institutes,
            builder: (context, state) => const InstituteManagementScreen(),
          ),
        ],
      ),
    ],
  );
}

