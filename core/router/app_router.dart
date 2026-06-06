import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/auth/presentation/login_screen.dart';
import 'package:abm_madrasa/features/dashboard/presentation/dashboard_screen.dart';
import 'package:abm_madrasa/features/teachers/presentation/teacher_management_screen.dart';
import 'package:abm_madrasa/features/teachers/presentation/progress_report_upload_screen.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/student_list_screen.dart';
import 'package:abm_madrasa/features/students/presentation/add_student_screen.dart';
import 'package:abm_madrasa/features/students/presentation/student_profile_screen.dart';
import 'package:abm_madrasa/features/students/presentation/parent_portal_screen.dart';
import 'package:abm_madrasa/features/students/presentation/online_admission_screen.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_mark_screen.dart';
import 'package:abm_madrasa/features/attendance/presentation/attendance_report_screen.dart';
import 'package:abm_madrasa/features/attendance/presentation/teacher_check_in_screen.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_screen.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_screen.dart';
import 'package:abm_madrasa/features/accounts/presentation/outstanding_dues_screen.dart';
import 'package:abm_madrasa/features/accounts/presentation/income_entry_screen.dart';
import 'package:abm_madrasa/features/finance/presentation/finance_screen.dart' as expenditure;
import 'package:abm_madrasa/features/events/presentation/event_list_screen.dart';
import 'package:abm_madrasa/features/settings/presentation/settings_screen.dart';
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

      if (isLoggingIn) {
        return user.role.defaultRoute;
      }

      if (module != null && !user.role.canAccess(module)) {
        return user.role.defaultRoute;
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
            builder: (context, state) => const AttendanceMarkScreen(),
          ),
          GoRoute(
            path: RouteNames.attendanceReport,
            builder: (context, state) => const AttendanceReportScreen(),
          ),
          GoRoute(
            path: RouteNames.teacherCheckIn,
            builder: (context, state) => const TeacherCheckInScreen(),
          ),
          GoRoute(
            path: RouteNames.progressReports,
            builder: (context, state) => const ProgressReportUploadScreen(),
          ),
          GoRoute(
            path: RouteNames.timetable,
            builder: (context, state) => const TimetableScreen(),
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
            path: RouteNames.institutes,
            builder: (context, state) => const InstituteManagementScreen(),
          ),
        ],
      ),
    ],
  );
}

