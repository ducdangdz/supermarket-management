import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import 'screens/attendance_overview_report_screen.dart';
import 'screens/employee_attendance_report_screen.dart';
import 'screens/late_absent_report_screen.dart';
import 'screens/detailed_attendance_history_screen.dart';
import 'screens/export_report_screen.dart';

/// Màn hình điều hướng trung tâm Phân hệ Báo cáo (Thành viên 4)
/// Tích hợp Thanh chuyển đổi Vai trò (Role Switcher: ADMIN, MANAGER, HR, EMPLOYEE)
class ReportsMainScreen extends StatefulWidget {
  const ReportsMainScreen({super.key});

  @override
  State<ReportsMainScreen> createState() => _ReportsMainScreenState();
}

class _ReportsMainScreenState extends State<ReportsMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Widget> _reportScreens = const [
    AttendanceOverviewReportScreen(), // Màn 1
    EmployeeAttendanceReportScreen(), // Màn 2
    LateAbsentReportScreen(), // Màn 3
    DetailedAttendanceHistoryScreen(), // Màn 4
    ExportReportScreen(), // Màn 5
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final currentRole = data.currentRoleCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Trung tâm Báo cáo & Thống kê',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Thông tin phân quyền',
            icon: const Icon(Icons.security_rounded),
            onPressed: () => _showRbacInfoDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // THANH ROLE SWITCHER (CHUYỂN ĐỔI VAI TRÒ ĐỂ DEMO NGAY)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.primaryDark,
                child: Row(
                  children: [
                    const Icon(Icons.switch_account_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    const Text(
                      'Thử nghiệm vai trò:',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ADMIN', 'MANAGER', 'HR', 'EMPLOYEE'].map((role) {
                            final isSelected = currentRole == role;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(role),
                                selected: isSelected,
                                selectedColor: AppColors.secondary,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                onSelected: (_) {
                                  data.setCurrentRole(role);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 1),
                                      content: Text('Đã chuyển vai trò sang: $role'),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 5 TAB TƯƠNG ỨNG 5 MÀN HÌNH BÁO CÁO THEO YÊU CẦU ĐỀ BÀI
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: '1. Tổng quan', icon: Icon(Icons.dashboard_rounded, size: 18)),
                  Tab(text: '2. Theo nhân viên', icon: Icon(Icons.badge_rounded, size: 18)),
                  Tab(text: '3. Đi muộn/Vắng', icon: Icon(Icons.alarm_off_rounded, size: 18)),
                  Tab(text: '4. Lịch sử chi tiết', icon: Icon(Icons.history_rounded, size: 18)),
                  Tab(text: '5. Xuất báo cáo', icon: Icon(Icons.file_download_rounded, size: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _reportScreens,
      ),
    );
  }

  void _showRbacInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Ma trận phân quyền (RBAC)'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ADMIN, MANAGER, HR: Xem được toàn bộ 5 màn hình báo cáo, bao gồm tổng quan, xuất file và xem lịch sử của mọi nhân viên.'),
            SizedBox(height: 10),
            Text('• EMPLOYEE: Bị giới hạn ở Màn 1, 2, 3, 5; Ở Màn 4 (Lịch sử chi tiết), EMPLOYEE chỉ được xem duy nhất lịch sử cá nhân của chính mình.'),
            SizedBox(height: 10),
            Text('💡 Mẹo: Dùng thanh "Thử nghiệm vai trò" phía trên để chuyển đổi tức thì giữa các quyền khi báo cáo đồ án!'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
        ],
      ),
    );
  }
}

