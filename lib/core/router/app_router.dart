import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/schedules/presentation/schedules_screen.dart';
import '../../features/schedules/presentation/schedule_detail_screen.dart';
import '../../features/attendance_history/presentation/attendance_history_screen.dart';
import '../../features/qr_checkin/presentation/qr_checkin_screen.dart';
import '../../navigation/employee_shell.dart';

class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthController authController) {
    final _rootNavigatorKey = GlobalKey<NavigatorState>();
    final _shellNavigatorKey = GlobalKey<NavigatorState>();
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/dashboard',
      refreshListenable: authController,
      redirect: (context, state) {
        final isAuthenticated = authController.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }
        if (isAuthenticated && isLoggingIn) {
          return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/qr-checkin',
          name: 'qr-checkin',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const QrCheckinScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => EmployeeShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/schedules',
              name: 'schedules',
              builder: (context, state) => const SchedulesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'schedule-detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      ScheduleDetailScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/attendance-history',
              name: 'attendance-history',
              builder: (context, state) => const AttendanceHistoryScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
