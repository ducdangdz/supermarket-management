import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import 'screens/attendance_overview_report_screen.dart';
import 'screens/employee_attendance_report_screen.dart';
import 'screens/late_absent_report_screen.dart';
import 'screens/detailed_attendance_history_screen.dart';
import 'screens/export_report_screen.dart';

class ReportsMainScreen extends StatelessWidget {
  const ReportsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(title: const Text('Báo cáo & thống kê')),
        body: Column(
          children: [
            if (!data.isRemote)
              ColoredBox(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Vai trò mẫu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final role in const [
                                'ADMIN',
                                'MANAGER',
                                'HR',
                                'EMPLOYEE',
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(role),
                                    selected: data.currentRoleCode == role,
                                    onSelected: (_) =>
                                        data.setCurrentRole(role),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const ColoredBox(
              color: AppColors.surface,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Theo nhân viên'),
                  Tab(text: 'Đi muộn / Vắng'),
                  Tab(text: 'Lịch sử chi tiết'),
                  Tab(text: 'Xuất báo cáo'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  AttendanceOverviewReportScreen(embedded: true),
                  EmployeeAttendanceReportScreen(embedded: true),
                  LateAbsentReportScreen(embedded: true),
                  DetailedAttendanceHistoryScreen(embedded: true),
                  ExportReportScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
