import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard/manager_dashboard_page.dart';
import 'floor_plan/floor_plan_page.dart';
import 'employees/employee_management_page.dart';
import 'shifts/shift_management_page.dart';
import 'schedules/schedule_management_page.dart';
import 'attendance_approval/attendance_approval_page.dart';
import '../reports/reports_main_screen.dart';

class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({super.key});

  @override
  State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ManagerDashboardPage(onNavigateToTab: _navigateToTab), // 0
      const FloorPlanPage(), // 1 - Mặt bằng trực quan
      const EmployeeManagementPage(), // 2 - Nhân viên
      const ShiftManagementPage(), // 3 - Ca làm
      const ScheduleManagementPage(), // 4 - Lịch làm
      const ReportsMainScreen(), // 5 - Trung tâm 5 màn hình Báo cáo & Thống kê
      const AttendanceApprovalPage(), // 6 - Duyệt bất thường
    ];
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 5 ? 0 : _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Mặt bằng 2D',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
            label: 'Nhân viên',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_history_outlined),
            selectedIcon: Icon(Icons.work_history_rounded, color: AppColors.primary),
            label: 'Ca làm',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            label: 'Xếp lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
            label: 'Báo cáo',
          ),
        ],
      ),
      // Drawer điều hướng tiện lợi cho cả 7 chức năng của Manager
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SmartMarket HRM',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Phân hệ Vận hành & Quản lý (Thành viên 4)',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            _buildDrawerTile(0, 'Tổng quan Dashboard', Icons.dashboard_rounded),
            _buildDrawerTile(1, 'Sơ đồ mặt bằng 2D (Trực quan)', Icons.map_rounded),
            _buildDrawerTile(2, 'Quản lý nhân viên', Icons.people_rounded),
            _buildDrawerTile(3, 'Quản lý ca làm việc', Icons.work_history_rounded),
            _buildDrawerTile(4, 'Phân công lịch làm việc', Icons.calendar_month_rounded),
            _buildDrawerTile(5, 'Báo cáo & Thống kê (5 màn hình)', Icons.analytics_rounded),
            const Divider(),
            _buildDrawerTile(6, 'Phê duyệt chấm công bất thường', Icons.fact_check_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryLight,
      onTap: () {
        Navigator.pop(context); // Đóng drawer
        setState(() => _currentIndex = index);
      },
    );
  }
}
