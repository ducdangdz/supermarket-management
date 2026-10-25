import 'package:provider/provider.dart';
import '../../services/mock_data_service.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/app_workspace.dart';
import 'dashboard/manager_dashboard_page.dart';
import 'floor_plan/floor_plan_page.dart';
import 'employees/employee_management_page.dart';
import 'shifts/shift_management_page.dart';
import 'schedules/schedule_management_page.dart';
import 'attendance_approval/attendance_approval_page.dart';
import '../reports/reports_main_screen.dart';

class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex < 7);
  final int initialIndex;
  @override
  State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  bool refreshing = false;
  Future<void> refresh() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      await context.read<MockDataService>().refresh();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  late int _currentIndex;
  final Set<int> _visited = {};
  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited.add(_currentIndex);
    _pages = [
      ManagerDashboardPage(onNavigateToTab: _navigateToTab),
      const FloorPlanPage(),
      const EmployeeManagementPage(),
      const ShiftManagementPage(),
      const ScheduleManagementPage(),
      const ReportsMainScreen(),
      const AttendanceApprovalPage(),
    ];
  }

  void _navigateToTab(int index) => setState(() {
    _currentIndex = index;
    _visited.add(index);
  });
  @override
  Widget build(BuildContext context) => AppWorkspace(
    title: 'Quản lý vận hành',
    selectedIndex: _currentIndex,
    onSelected: _navigateToTab,
    onExit: () => Navigator.of(context).pop(),
    mobileIndices: const [0, 2, 4, 5],
    destinations: const [
      WorkspaceDestination('Tổng quan', Icons.dashboard_outlined),
      WorkspaceDestination('Mặt bằng', Icons.map_outlined),
      WorkspaceDestination('Nhân viên', Icons.people_outline_rounded),
      WorkspaceDestination('Ca làm', Icons.work_history_outlined),
      WorkspaceDestination('Xếp lịch', Icons.calendar_month_outlined),
      WorkspaceDestination('Báo cáo', Icons.insights_outlined),
      WorkspaceDestination('Phê duyệt', Icons.fact_check_outlined),
    ],
    child: Column(
      children: [
        if (context.watch<MockDataService>().isRemote)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.watch<MockDataService>().currentRoleCode == 'ADMIN'
                        ? 'Quản trị hệ thống · Tất cả chi nhánh'
                        : context
                              .watch<MockDataService>()
                              .currentBranch
                              .branchName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (refreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Làm mới dữ liệu',
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final index in _visited)
                Offstage(
                  offstage: index != _currentIndex,
                  child: TickerMode(
                    enabled: index == _currentIndex,
                    child: _pages[index],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
