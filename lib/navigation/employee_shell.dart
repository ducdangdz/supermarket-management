import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_workspace.dart';

class EmployeeShell extends StatelessWidget {
  const EmployeeShell({super.key, required this.child});
  final Widget child;
  static const _routes = [
    '/dashboard',
    '/schedules',
    '/attendance-history',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _routes.indexWhere(
      (route) => location.startsWith(route),
    );
    return AppWorkspace(
      title: 'Không gian nhân viên',
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onSelected: (index) => context.go(_routes[index]),
      destinations: const [
        WorkspaceDestination('Tổng quan', Icons.dashboard_outlined),
        WorkspaceDestination('Lịch làm', Icons.calendar_month_outlined),
        WorkspaceDestination('Chấm công', Icons.history_rounded),
        WorkspaceDestination('Cá nhân', Icons.person_outline_rounded),
      ],
      child: child,
    );
  }
}
